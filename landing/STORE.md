# App Store / TestFlight prep — Press Start

## Listing

| Field | Value |
| --- | --- |
| Name | Press Start |
| Subtitle | Retro Emulator · GB GBA NES SNES |
| Bundle ID | `com.nikolaikushner.pressstart` |
| Category | Games → Simulation (or Action) |
| Age | 12+ (Infrequent/Mild Cartoon Violence; user-supplied content) |
| Price | **$1.49** paid upfront; no IAP for ROMs |
| Privacy policy | https://nikolaikushner.github.io/PressStart/privacy.html |
| Support / source | https://github.com/nikolaikushner/PressStart |
| Marketing | https://nikolaikushner.github.io/PressStart/ |

## Privacy (App Privacy questionnaire)

- Data collection: **No** (no analytics account for v1).
- No tracking, no account, no cloud sync in v1.
- User-imported ROMs and saves stay in the app Documents folder on device.

## Export compliance

- Uses only standard HTTPS / OS encryption → typically **exempt** (answer the usual “encryption only for info security / HTTPS” path).

## Review notes (paste into App Store Connect)

```
Press Start is a paid ($1.49) local emulator shelf. Users import ROM files they already own via the system Files picker. The app does not download, sell, or host commercial game ROMs.

Emulation uses open-source DeltaCore system cores (AGPL-3.0). Corresponding source for this app is publicly available at:
https://github.com/nikolaikushner/PressStart

On-screen controller art does not use Nintendo trademarks. No account system. No analytics in v1.
Privacy policy: https://nikolaikushner.github.io/PressStart/privacy.html
```

## Screenshots checklist

1. Empty shelf with PRESS START wordmark and Add dock  
2. Grouped library with a few covers  
3. Play screen — handheld shell, game on top  
4. Licenses screen (shows GitHub source link)

Capture on iPhone 15/16 Pro sizes in portrait. App icon: glass Select/Start capsules on black (`brand/press-start-icon.png`).

## TestFlight

1. Archive in Xcode with your Apple Developer team.  
2. Upload to App Store Connect → TestFlight.  
3. Internal testers first; paste the review notes above.
