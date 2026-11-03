# Porting status

**Working branch:** `switch-port-dev`  
**Base:** `FunkinCrew/Funkin` (official V-Slice source)  
**Windows support:** retained as a separate desktop target  
**Nintendo Switch support:** early integration / source compilation still being debugged

## Changes committed so far

- Added Switch target configuration to `project.hxp`, including the OpenGL Lime-NX defines and Switch-specific window settings.
- Added separate dependency manifests: `hmm.json` retains the official desktop library pins, while `hmm-switch.json` pins the Switch-compatible Lime-NX, HXCPP-NX, OpenFL, Flixel, and FlxAnimate libraries.
- Added `hx_libnx` and the Haxe HScript dependency used by the Switch branch.
- Kept the standard Windows target in the project configuration.
- Added Switch startup selection in `source/Main.hx`; Windows still creates the normal `FlxGame`.
- Added native HID polling and a precise rhythm-input bridge for D-pad and Y/B/X/A button press/release transitions.
- On Switch, precise rhythm input uses libnx exclusively to avoid SDL/libnx double-dispatch; SDL remains enabled for general menu navigation and sticks.
- Configured persistent saves under the Switch SD card's `switch/Funkin-Switch/saves` directory.
- Redirected crash reports and debug trace logs to `sdmc:/switch/Funkin-Switch/logs`; Switch directory creation now builds missing parent folders on a fresh SD card.
- Routed the user mods folder to `sdmc:/switch/Funkin-Switch/mods` so startup never tries to create it inside read-only ROMFS.
- Added a CI workflow with separate Windows and Switch build jobs.

## Not verified yet

- Full Haxe source compilation on either target. The Switch toolchain, HXP asset generation, HXCPP build tools, and Lime-NX native rebuild have completed in CI; the remaining source compile errors are being resolved. Windows previously compiled against the Switch-only Lime/OpenFL forks by mistake; the workflow now selects the upstream desktop dependency manifest for Windows.
- Windows executable launch or gameplay.
- Switch NRO generation or launch.
- Joy-Con, paired Joy-Con, or Pro Controller testing on hardware.
- Menu focus and controller reconnection.
- Audio timing, video cutscenes, suspend/resume, or save persistence on hardware.
- 60 FPS performance in handheld or docked mode.

## Known limitations / next work

- Switch video playback is currently disabled; the upstream desktop `hxvlc` dependency does not provide the Switch video path used by this build.
- The title ID is a development placeholder.
- Menu controls currently depend on the Lime/SDL gamepad backend; the native HID bridge added so far is specifically for precise rhythm inputs.
- A successful CI build is only a compile result. It does not substitute for physical-console testing.
- Asset redistribution is restricted by the separate proprietary `Funkin.assets` license. Binary artifact upload is disabled while this repository is public.
