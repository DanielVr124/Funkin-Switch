# Porting status

**Working branch:** `switch-port-dev`  
**Base:** `FunkinCrew/Funkin` (official V-Slice source)  
**Windows support:** retained as a separate desktop target  
**Nintendo Switch support:** early native port; first full Switch C++ build is still in progress

## Latest CI evidence

The latest paired build is [GitHub Actions run 41758302468](https://github.com/DanielVr124/Funkin-Switch/actions/runs/41758302468), on commit `d3414dda74fd0bbb7192b0cbac10cdb7e5e2ca38`.

- **Windows:** Haxe compilation, HXCPP setup, Lime rebuild, game compilation, and Windows ZIP packaging all succeeded. The archive was not uploaded because the repository is public and the package includes assets covered by the separate proprietary `Funkin.assets` license.
- **Switch:** dependency installation, HXCPP build-tool compilation, asset/project generation, and Lime-NX native rebuild succeeded. The actual game build passed Haxe source compilation and advanced into native AArch64 C++ compilation. The NRO link and SD-card ZIP packaging have not completed yet.
- **Artifacts:** none were published by this run. The workflow uploads the game packages only when the repository is private.

A successful Windows compile does not prove that the application was launched or gameplay-tested. A successful Switch compile will not prove that the NRO runs on a physical console.

## Changes committed so far

- Added Switch target configuration to `project.hxp`, including OpenGL Lime-NX defines and Switch-specific window settings.
- Added separate dependency manifests: `hmm.json` retains desktop pins, while `hmm-switch.json` pins Switch-compatible Lime-NX, HXCPP-NX, OpenFL, Flixel, and FlxAnimate dependencies.
- Added `hx_libnx` and the Haxe HScript dependency used by the Switch build.
- Kept the standard Windows target in the project configuration and separated the Windows and Switch dependency sets in CI.
- Added Switch startup selection in `source/Main.hx`; Windows still creates the normal `FlxGame`.
- Added native HID polling and a precise rhythm-input bridge for D-pad and Y/B/X/A button press/release transitions.
- On Switch, precise rhythm input uses libnx exclusively to avoid SDL/libnx double-dispatch; SDL remains enabled for general menu navigation and sticks.
- Added a Lime-NX compatibility path for FlxAnimate render-texture checks.
- Added a platform-neutral VSync preference type and bridge between desktop Lime's API and Lime-NX's API.
- Configured persistent saves under `sdmc:/switch/Funkin-Switch/saves`.
- Redirected crash reports and debug trace logs to `sdmc:/switch/Funkin-Switch/logs`; Switch directory creation now builds missing parent folders on a fresh SD card.
- Routed the user mods folder to `sdmc:/switch/Funkin-Switch/mods` so startup does not try to create it inside read-only ROMFS.
- Added CI workflows with separate Windows and Switch build jobs.

## Not verified yet

- Successful final NRO link and SD-card package generation.
- Windows executable launch or gameplay on a real Windows machine.
- NRO launch on emulator or physical Nintendo Switch.
- Joy-Con, paired Joy-Con, or Pro Controller behavior on hardware.
- Menu focus, controller reconnect, suspend/resume, and home-menu return.
- Song playback, audio timing, note timing, and long-session stability on Switch.
- Save persistence and mod loading on a physical SD card.
- 60 FPS performance in handheld or docked mode.

## Known limitations / next work

- Switch video playback is disabled because the current target setup does not include the desktop `hxvlc` backend. Windows keeps the existing video playback implementation.
- Rhythm-lane mapping is currently hard-coded to D-pad and Y/B/X/A; remapping UI and all controller layouts are not implemented or verified.
- HD rumble is not implemented.
- The title ID remains a development placeholder.
- The current project still needs Switch-specific lazy loading of non-default asset libraries and a forced 60 FPS cap before a test package should be treated as performance-tuned.
- A successful CI build is only a compile result. It does not substitute for physical-console testing.

## Asset and artifact handling

The game source code and the game's content have separate licensing. The upstream `Funkin.assets` license states that its art, visual assets, audio, music, sound effects, and other creative content are proprietary and may not be redistributed by third parties. Do not publish binary builds containing those assets in public Releases or public Actions artifacts unless the rights holder authorizes that distribution.

The CI workflow therefore builds both targets on the public development branch but only uploads binary artifacts when the repository is private. The repository can remain public for source work; making it private is required for this workflow to provide private test-package downloads.
