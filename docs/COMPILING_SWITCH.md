# Nintendo Switch release build

This project builds an unofficial homebrew NRO for a modded Nintendo Switch.

## GitHub Actions release build

The dedicated workflow is **Nintendo Switch Release Build**:

- Open the repository's Actions tab.
- Select **Nintendo Switch Release Build**.
- Choose **Run workflow** on the `main` branch.
- Open the completed run and download the `Funkin-Switch-Release-<commit>` artifact.

The artifact contains both `Funkin.nro` and an SD-card installation ZIP. It is uploaded only when this repository is private because the bundled game assets are proprietary. Artifacts are retained for 14 days.

Changes to Switch-relevant source, assets, manifests, and build files on `main` also trigger the workflow automatically.

## Local Windows build

Install Haxe 4.3.7, Git, Python, DevKitPro with DevKitA64, and the Switch packages required by Lime-NX. Complete the standard Haxe/HMM setup from [COMPILING.md](COMPILING.md), then run:

```text
scripts\itch-building\build-lime-SWITCH.bat
```

The script temporarily selects `hmm-switch.json`, installs the Switch-specific dependencies, applies the OpenFL compatibility patches, rebuilds Lime's Windows host runtime and Switch target runtime, builds the NRO, and restores the normal desktop `hmm.json` afterward.

Expected output:

```text
export\release\switch\bin\Funkin.nro
```

## Switch-specific dependencies

The Switch manifest is aligned with the dependency pins used by the matching upstream FNF Switch port: Lime-NX, HXCPP-NX, current FunkinCrew Flixel and Flixel-addons, and FunkinCrew OpenFL. It additionally pins `hx_libnx` for the Switch controller and system bindings. Keep these Switch-specific dependencies separate from the normal desktop `hmm.json`.
