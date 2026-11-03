# Vendor

Emulation dependencies are **not** committed here (too large). Clone them with:

```bash
./PressStart/scripts/bootstrap-cores.sh
```

| Folder | Role | License |
| --- | --- | --- |
| `DeltaCore/` | SPM package (Package.swift patched to iOS 17) | AGPL-3.0 |
| `GBCDeltaCore/` | GB / GBC | AGPL-3.0 |
| `GBADeltaCore/` | GBA | AGPL-3.0 |
| `NESDeltaCore/` | NES | AGPL-3.0 |
| `SNESDeltaCore/` | SNES | AGPL-3.0 |
| `GPGXDeltaCore/` | Mega Drive | AGPL-3.0 |

Link the five system frameworks in Xcode after bootstrap. See [SOURCE.md](../SOURCE.md) and [NOTICE](../NOTICE).
