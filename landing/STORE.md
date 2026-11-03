# App Store / TestFlight prep — Press Start

## Listing

| Field | Value |
| --- | --- |
| Name | Press Start |
| Subtitle | Retro Emulator · GB GBA NES SNES |
| Bundle ID | `com.nikolaikushner.pressstart` |
| Category | Games → Simulation (or Action) |
| Age | 12+ (Infrequent/Mild Cartoon Violence; user-supplied content) |
| Price | **$1.49** (≈ $1.50) paid upfront; no IAP for ROMs |

## Privacy

- Collects: none (no analytics account required for v1).
- Data not linked to you: files the user imports stay on-device in Documents.
- Privacy policy URL: host a short page (can reuse `landing/` or GitHub Pages) stating: no account, no tracking, user-imported ROMs only, saves on device.

## Review notes (paste into App Store Connect)

Press Start is a paid local emulator shelf ($1.49). Users import ROM files they already own via the system Files picker. The app does not download, sell, or host commercial game ROMs. Emulation uses open-source DeltaCore system cores (AGPL). On-screen controller art does not use Nintendo trademarks. The Press Start UI is proprietary; AGPL applies to linked cores — corresponding source for AGPL components is offered at https://github.com/nikolaikushner/PressStart when those cores are shipped.

## Screenshots checklist

1. Empty shelf with PRESS START wordmark and Add dock  
2. Grouped library with a few covers  
3. Play screen — handheld shell, game on top  
4. Optional: gamepad connected / Licenses screen

Capture on iPhone 15/16 Pro sizes in portrait.

## TestFlight

1. Archive in Xcode with your Apple Developer team.  
2. Upload to App Store Connect → TestFlight.  
3. Internal testers first; attach the review notes above.
