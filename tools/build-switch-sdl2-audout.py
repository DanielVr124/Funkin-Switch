#!/usr/bin/env python3
"""Build the devkitPro SDL2 2.28.5-3 audout backend for the Switch test NRO.

The current container ships SDL2 2.28.5-4, which switched its Switch audio
service from audout to audren. This reproduces the official devkitPro 2.28.5-3
source build, but installs only libSDL2.a so the rest of the pinned toolchain
and portlibs remain unchanged.
"""
from __future__ import annotations

import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from urllib.request import urlopen


SDL_VERSION = "2.28.5"
SDL_SOURCE_URL = f"https://www.libsdl.org/release/SDL2-{SDL_VERSION}.tar.gz"
SDL_SOURCE_SHA256 = "332cb37d0be20cb9541739c61f79bae5a477427d79ae85e352089afdaf6666e4"

# Exact devkitPro pacman-packages revision that published switch-sdl2 2.28.5-3.
DEVKITPRO_PACKAGE_REVISION = "0ae8790f6e092cf8df937d143e70a785f7e27997"
SDL_PATCH_URL = (
    "https://raw.githubusercontent.com/devkitPro/pacman-packages/"
    f"{DEVKITPRO_PACKAGE_REVISION}/switch/SDL2/SDL2-2.28.5.patch"
)
SDL_PATCH_SHA256 = "f5cf0336980c88559594cc30205022bdcf84be00e437e8b28f43a15dcbe0a58d"


def download_verified(url: str, destination: Path, expected_sha256: str) -> None:
    print(f"Downloading {url}", flush=True)
    digest = hashlib.sha256()
    with urlopen(url, timeout=60) as response, destination.open("wb") as output:
        while chunk := response.read(1024 * 1024):
            digest.update(chunk)
            output.write(chunk)
    actual = digest.hexdigest()
    if actual != expected_sha256:
        raise SystemExit(
            f"SHA-256 mismatch for {url}: expected {expected_sha256}, got {actual}"
        )


def run(command: list[str], *, cwd: Path | None = None) -> str:
    completed = subprocess.run(
        command,
        cwd=cwd,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    return completed.stdout


def main() -> None:
    devkitpro = Path(os.environ.get("DEVKITPRO", "/opt/devkitpro"))
    switchvars = devkitpro / "switchvars.sh"
    if not switchvars.is_file():
        raise SystemExit(f"Missing devkitPro environment script: {switchvars}")

    prefix_output = run(
        ["bash", "-c", f'source "{switchvars}" && printf "%s" "$PORTLIBS_PREFIX"']
    ).strip()
    if not prefix_output:
        raise SystemExit("switchvars.sh did not define PORTLIBS_PREFIX")
    prefix = Path(prefix_output)
    destination = prefix / "lib" / "libSDL2.a"
    if not destination.is_file():
        raise SystemExit(f"Installed SDL2 archive not found: {destination}")

    nm = shutil.which("aarch64-none-elf-nm")
    if not nm:
        candidate = devkitpro / "devkitA64" / "bin" / "aarch64-none-elf-nm"
        if candidate.is_file():
            nm = str(candidate)
    if not nm:
        raise SystemExit("aarch64-none-elf-nm was not found in the Switch toolchain")

    with tempfile.TemporaryDirectory(prefix="switch-sdl2-audout-") as temp:
        work = Path(temp)
        archive = work / f"SDL2-{SDL_VERSION}.tar.gz"
        patch_file = work / "SDL2-2.28.5.patch"
        download_verified(SDL_SOURCE_URL, archive, SDL_SOURCE_SHA256)
        download_verified(SDL_PATCH_URL, patch_file, SDL_PATCH_SHA256)

        run(["tar", "-xzf", str(archive), "-C", str(work)])
        source = work / f"SDL2-{SDL_VERSION}"
        if not source.is_dir():
            raise SystemExit("SDL2 source archive did not extract as expected")

        run(["patch", "--batch", "--forward", "-p1", "-i", str(patch_file)], cwd=source)

        jobs = str(os.cpu_count() or 2)
        build_script = f"""
set -e
source "{switchvars}"
./configure --prefix="$PORTLIBS_PREFIX" --host=aarch64-none-elf \\
  --disable-shared --enable-static \\
  --enable-audio --enable-joystick --disable-power --disable-filesystem \\
  --enable-cpuinfo --enable-pthreads --enable-timers --enable-video
make -j{jobs}
"""
        print("Building SDL2 2.28.5 with the devkitPro audout backend...", flush=True)
        print(run(["bash", "-c", build_script], cwd=source), flush=True)

        built_archives = list(source.rglob("libSDL2.a"))
        if len(built_archives) != 1:
            raise SystemExit(
                "Expected one freshly built libSDL2.a, found: "
                + ", ".join(str(path) for path in built_archives)
            )
        built_archive = built_archives[0]

        symbols = run([nm, "-g", str(built_archive)])
        undefined = run([nm, "-u", str(built_archive)])
        if "SWITCHAUDIOOUT_bootstrap" not in symbols:
            raise SystemExit("Built SDL2 archive does not contain the audout driver")
        if "audoutInitialize" not in undefined:
            raise SystemExit("Built SDL2 archive does not reference audoutInitialize")
        if "audrenInitialize" in undefined:
            raise SystemExit("Built SDL2 archive unexpectedly references audrenInitialize")

        replacement = destination.with_name("libSDL2.a.audout-test")
        shutil.copy2(built_archive, replacement)
        replacement.replace(destination)

    print(
        "Installed SDL2 2.28.5-3-compatible audout backend at "
        f"{destination}; verified SWITCHAUDIOOUT_bootstrap/audout symbols.",
        flush=True,
    )


if __name__ == "__main__":
    main()
