# Vendor

- `DeltaCore/` — local SPM package used by Press Start (Package.swift patched to iOS 17 / Swift tools 5.9).
- `GBCDeltaCore`, `GBADeltaCore`, `NESDeltaCore`, `SNESDeltaCore`, `GPGXDeltaCore` — clone with `PressStart/scripts/bootstrap-cores.sh`, then link the frameworks in Xcode. Not required for the shelf UI build.
