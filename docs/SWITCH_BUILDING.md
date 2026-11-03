# Nintendo Switch build notes

This project keeps the official Windows desktop target and adds a separate Nintendo Switch homebrew target. Switch-only code is guarded by the Haxe `switch` define so the Windows build continues to use the standard `FlxGame` and Lime desktop backend.

## Toolchain

The Switch target currently uses the experimental Lime-NX backend with its matching HXCPP fork and libnx Haxe bindings:

- Lime-NX: https://github.com/Slushi-Github/lime-nx/tree/lime-9778682
- HXCPP-NX: https://github.com/Slushi-Github/hxcpp-nx
- hx_libnx: https://github.com/Slushi-Github/hx_libnx
- devkitPro / devkitA64: https://devkitpro.org/

Install Haxe 4.3.7, Git, devkitPro with the Switch development packages, and the dependencies listed by the Lime-NX README. Then, from the repository root:

```sh
haxelib --global install hmm
haxelib --global run hmm setup
hmm install
haxelib run lime setup
haxelib run lime rebuild switch
haxelib run lime build switch -debug
```

For Windows desktop:

```sh
haxelib run lime setup
haxelib run lime rebuild windows
haxelib run lime build windows -debug
```

The repository's `.github/workflows/build-platforms.yml` runs both targets on the `switch-port-dev` branch. The Switch job uses the devkitPro `devkita64` container. On a private repository, it also packages `Funkin.nro` and an SD-card ZIP containing `switch/Funkin-Switch/Funkin.nro`.

## Current Switch integration

- Switch startup changes the working directory to `romfs:/` for packaged, read-only game assets.
- Persistent save data is directed to `sdmc:/switch/Funkin-Switch/saves`.
- User-installed mods are read from `sdmc:/switch/Funkin-Switch/mods`.
- Crash reports and debug trace logs are written to `sdmc:/switch/Funkin-Switch/logs`.
- Controller polling uses libnx `Pad` / HID APIs.
- D-pad and face-button presses and releases are routed to the official precise rhythm input manager:
  - Y / D-pad Left: Left
  - B / D-pad Down: Down
  - X / D-pad Up: Up
  - A / D-pad Right: Right
- Standard Lime/SDL gamepad handling remains in place for the rest of the UI. Native libnx polling is the single rhythm-lane input source to avoid double-dispatch. Menu focus, reconnection, and all controller layouts still require runtime verification.
- Video playback is disabled on Switch for now because the current target setup does not include the desktop `hxvlc` backend. Windows keeps the existing video playback implementation.

The Switch title ID in `project.hxp` is a development placeholder. A final package should use a unique title ID and a confirmed application icon.

## Testing status

Do not interpret a successful source edit or a successful compiler invocation as proof that the game works on a console. Track these separately:

1. Source configuration reviewed.
2. Windows or Switch compiler completes.
3. App launches in an emulator or on-device test environment.
4. Game menus and controller navigation work.
5. Full songs run with synchronized audio and accurate note timing.
6. The same tests pass on physical Switch hardware in handheld and docked modes.

No Switch hardware test or 60 FPS measurement is claimed yet.

## Asset and redistribution note

The game source code and the game's content have separate licensing. The upstream `Funkin.assets` license states that its art, visual assets, audio, music, sound effects, and other creative content are proprietary and may not be redistributed by third parties. Keep any binary build containing those assets private and do not publish it as a public release unless the rights holder authorizes that distribution.

The CI workflow therefore builds both targets on the public development branch but only uploads binary artifacts when the repository is private. The source fork itself can remain public, but public users should not receive packaged proprietary game content through Actions artifacts or Releases.
