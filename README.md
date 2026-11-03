<p align="center">
  <img src="brand/press-start-logo.png" alt="Press Start" width="280">
</p>

<h1 align="center">Press Start</h1>

<p align="center">
  <strong>Native iPhone shelf</strong> for the Game Boy, GBA, NES, SNES, and Mega Drive games you own.<br>
  Full-speed play · GameSir ready · Saves stay on your phone
</p>

<p align="center">
  <a href="https://nikolaikushner.github.io/PressStart/">Landing page</a>
  ·
  <a href="landing/STORE.md">App Store prep</a>
  ·
  <a href="landing/privacy.html">Privacy</a>
  ·
  <a href="LICENSE">AGPL-3.0</a>
</p>

---

| | |
| --- | --- |
| **Brand** | Press Start |
| **Bundle ID** | `com.nikolaikushner.pressstart` |
| **Subtitle** | `Retro Emulator · GB GBA NES SNES` |
| **Systems** | GB · GBC · GBA · NES · SNES · Mega Drive |
| **UI** | SwiftUI shelf (not Delta branding) |
| **Engine** | [DeltaCore](https://github.com/rileytestut/DeltaCore) + system cores |

The Safari / EmulatorJS player is retired. This repository is the **native app** plus a small marketing site for GitHub Pages.

## Build

1. Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).
2. Bootstrap DeltaCore (and optionally the five system cores):

```bash
./PressStart/scripts/bootstrap-cores.sh
```

3. Generate and open the project:

```bash
cd PressStart
xcodegen generate
open PressStart.xcodeproj
```

4. Select your Apple Developer team, then run on an iPhone or simulator.
5. Link `GBCDeltaCore`, `GBADeltaCore`, `NESDeltaCore`, `SNESDeltaCore`, and `GPGXDeltaCore` from `Vendor/` in Xcode for real gameplay. Without them the shelf, import, skins, and GameSir routing still build; play shows a core-missing message until the frameworks are linked.

`CoreRegistry` registers cores automatically when those modules are present (`canImport`).

## What’s in the app

- Dark shelf grouped by console, search, frosted **Games | Add** dock  
- ROM import via Files with byte-based console detection  
- Pocket / Advance on-screen shells (no console trademarks)  
- Soft-pad hits + `GameController` GameSir polling  
- On-disk SRAM and save states under Documents  
- Cover snapshots after play  
- In-app Licenses (AGPL + engine attribution)

## License & legal

Application code ships under **AGPL-3.0** when DeltaCore and the system cores are linked. Do not distribute commercial ROMs. Bring your own legally obtained backups — the app does not download games.
