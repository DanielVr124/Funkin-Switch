#!/usr/bin/env python3
"""Give the Switch MPV build its own SDL2 symbol namespace.

Lime links SDL3, while devkitPro's prebuilt libmpv.a uses SDL2. Their C APIs
export overlapping names. Rename SDL2 definitions and MPV's corresponding
references, rebuilding each archive from individually transformed members.
"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


LIB_DIR = Path("/opt/devkitpro/portlibs/switch/lib")
SDL2 = LIB_DIR / "libSDL2.a"
MPV = LIB_DIR / "libmpv.a"

DEVKITPRO = Path(os.environ.get("DEVKITPRO", "/opt/devkitpro"))
DEVKITA64 = Path(os.environ.get("DEVKITA64", str(DEVKITPRO / "devkitA64")))
TOOL_BIN = DEVKITA64 / "bin"


def find_tool(*names: str) -> str:
    """Find a devkitA64 tool even when its bin directory is not on PATH."""
    checked = []
    for name in names:
        candidate = TOOL_BIN / name
        checked.append(str(candidate))
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return str(candidate)

        located = shutil.which(name)
        if located:
            return located

    raise SystemExit(
        "Required Switch binutils tool not found. Checked: "
        + ", ".join(checked)
        + ". Expected the devkitA64 tools under "
        + str(TOOL_BIN)
    )


NM = find_tool("aarch64-none-elf-nm", "aarch64-none-elf-gcc-nm")
OBJCOPY = find_tool("aarch64-none-elf-objcopy")
AR = find_tool("aarch64-none-elf-ar", "aarch64-none-elf-gcc-ar")


def run(*args: str, cwd: Path | None = None) -> str:
    return subprocess.check_output(
        args, cwd=cwd, text=True, stderr=subprocess.STDOUT
    )


def symbols_from_nm(output: str, prefix: str) -> set[str]:
    found = set()
    for line in output.splitlines():
        fields = line.split()
        if fields and fields[-1].startswith(prefix):
            found.add(fields[-1])
    return found


def transform_archive(
    source: Path, destination: Path, map_file: Path, temp_root: Path
) -> None:
    """Transform each archive member separately, then recreate its index.

    Running objcopy on the archive as a whole can leave members unchanged with
    some cross-binutils builds. Extracting and transforming each ELF object
    makes the symbol rewrite explicit and lets ar rebuild a correct index.
    """
    member_names = [
        line.strip()
        for line in run(AR, "t", str(source)).splitlines()
        if line.strip()
    ]
    if not member_names:
        raise SystemExit(f"No members found in static archive: {source}")
    if len(member_names) != len(set(member_names)):
        raise SystemExit(
            f"Archive has duplicate member names; refusing lossy extraction: {source}"
        )

    work = temp_root / (source.stem + "-members")
    work.mkdir()
    run(AR, "x", str(source), cwd=work)

    missing = [name for name in member_names if not (work / name).is_file()]
    if missing:
        raise SystemExit(
            f"Could not extract {len(missing)} member(s) from {source}: "
            + ", ".join(missing[:10])
        )

    for name in member_names:
        original = work / name
        transformed = work / (name + ".renamed")
        run(
            OBJCOPY,
            f"--redefine-syms={map_file}",
            str(original),
            str(transformed),
        )
        transformed.replace(original)

    # Recreate the archive and its symbol index, retaining the member order.
    run(AR, "rcsD", str(destination), *member_names, cwd=work)


for library in (SDL2, MPV):
    if not library.is_file():
        raise SystemExit(f"Required Switch static library is missing: {library}")

# Gather all SDL2 definitions and confirm MPV only references symbols present
# in the SDL2 archive before modifying either library.
symbols = symbols_from_nm(
    run(NM, "-g", "--defined-only", str(SDL2)), "SDL_"
)
if not symbols:
    raise SystemExit(f"No exported SDL2 symbols found in {SDL2}")

mpv_sdl_refs = symbols_from_nm(run(NM, "-u", str(MPV)), "SDL_")
missing_refs = sorted(mpv_sdl_refs - symbols)
if missing_refs:
    raise SystemExit(
        "MPV references SDL symbols not exported by libSDL2.a:\n"
        + "\n".join(missing_refs[:40])
    )

mapping = {name: "MPVSDL2_" + name for name in sorted(symbols)}

with tempfile.TemporaryDirectory(prefix="switch-sdl2-namespace-") as temp:
    temp_path = Path(temp)
    map_file = temp_path / "symbols.map"
    map_file.write_text(
        "".join(f"{old} {new}\n" for old, new in mapping.items()),
        encoding="utf-8",
    )

    patched_sdl2 = temp_path / "libSDL2.a"
    patched_mpv = temp_path / "libmpv.a"

    transform_archive(SDL2, patched_sdl2, map_file, temp_path)
    transform_archive(MPV, patched_mpv, map_file, temp_path)

    remaining = symbols_from_nm(
        run(NM, "-g", "--defined-only", str(patched_sdl2)), "SDL_"
    )
    if remaining:
        raise SystemExit(
            "SDL2 archive still has unprefixed defined symbols after per-member "
            "rewriting:\n" + "\n".join(sorted(remaining)[:40])
        )

    unresolved = symbols_from_nm(run(NM, "-u", str(patched_mpv)), "SDL_")
    if unresolved:
        raise SystemExit(
            "MPV still has unprefixed SDL references after per-member rewriting:\n"
            + "\n".join(sorted(unresolved)[:40])
        )

    # Replace atomically only after both rebuilt archives pass verification.
    SDL2.replace(patched_sdl2)
    MPV.replace(patched_mpv)

print(
    f"Isolated {len(mapping)} SDL2 symbols under the MPVSDL2_ prefix across "
    "both archives; Lime's SDL3 symbols remain unchanged."
)
