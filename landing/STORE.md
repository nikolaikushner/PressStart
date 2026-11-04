# App Store / TestFlight prep — Press Start

## Listing

| Field | Value |
| --- | --- |
| Name | Press Start |
| Subtitle | Retro Emulator · GB GBA NES SNES |
| Bundle ID | `com.nikolaikushner.pressstart` |
| Category | Games → Simulation (or Action) |
| Age | 12+ (Infrequent/Mild Cartoon Violence; user-supplied content) |
| Purchases | No in-app purchases and no ROM store |
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
Press Start is a local emulator shelf. Users import ROM files they already own via the system Files picker. The app does not download, sell, or host commercial game ROMs.

Emulation uses open-source DeltaCore system cores (AGPL-3.0). Corresponding source for this app is publicly available at:
https://github.com/nikolaikushner/PressStart

On-screen controller art does not use Nintendo trademarks. No account system. No analytics in v1.
Privacy policy: https://nikolaikushner.github.io/PressStart/privacy.html
```

## Screenshots checklist

Simulator captures are in `landing/screenshots/`:

1. `shelf.png` — empty shelf, PRESS START wordmark, Add dock (iPhone 17)
2. `play.png` — play screen, handheld shell, game on top (Delta’s controller hidden)
3. `shelf-6.9.png` (1320×2868) and `shelf-6.3.png` (1206×2622) — shelf with original covers for GB, GBA, NES, SNES, and Mega Drive
4. `licenses-6.9.png` (1320×2868) and `licenses-6.3.png` (1206×2622) — Licenses, including the GitHub source link

Portrait sizes match App Store Connect’s 6.9" and 6.3" iPhone slots. Covers in those shots are original art, not commercial box art. App icon: glass Select/Start capsules on black (`brand/press-start-icon.png`).

## TestFlight

Signing team in `PressStart/project.yml`: `S37Z4QU5FT` (Mikalai Kushner — the Apple ID currently signed into Xcode). Pass the same team on the command line so the vendored cores, which ship with someone else’s team id, sign with yours.

1. `cd PressStart && xcodegen generate`
2. Archive: Product → Archive, or

```bash
xcodebuild -project PressStart.xcodeproj -scheme PressStart \
  -destination 'generic/platform=iOS' \
  -archivePath build/PressStart.xcarchive \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=S37Z4QU5FT \
  archive
```

Apple Distribution certificate on this Mac: `Apple Distribution: Mikalai Kushner (S37Z4QU5FT)` (created 3 Nov 2026, expires 3 Nov 2027). The archive from step 2 is development-signed. Export re-signs it for TestFlight:

```bash
xcodebuild -exportArchive \
  -archivePath build/PressStart.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates
```

Ready locally, not uploaded: `PressStart/build/export/PressStart.ipa` (profile `iOS Team Store Provisioning Profile: com.nikolaikushner.pressstart`, `get-task-allow` false, `beta-reports-active` true, certificate `Apple Distribution: Mikalai Kushner (S37Z4QU5FT)`).
3. Upload that IPA to App Store Connect → TestFlight when asked.
4. Internal testers first; paste the review notes above.

Privacy policy URL: https://nikolaikushner.github.io/PressStart/privacy.html  
Support URL: https://github.com/nikolaikushner/PressStart

Cores (GBC, GBA, NES, SNES, Genesis Plus GX) are linked from `Vendor/` by XcodeGen. Corresponding source for the AGPL components is the public Press Start repository plus the DeltaCore core repositories cloned by `PressStart/scripts/bootstrap-cores.sh`.

GitHub’s social preview image is not settable through the public API. Set it in the repo settings (Social preview) to `brand/press-start-icon.png`. The README and the Pages site already use that icon (`og:image`).
