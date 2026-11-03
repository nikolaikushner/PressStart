#!/usr/bin/env bash
# Clone Delta system cores into ../Vendor for local Xcode linking.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VENDOR="$ROOT/Vendor"
mkdir -p "$VENDOR"

# DeltaCore is vendored under Vendor/DeltaCore (Package.swift patched to iOS 17).
if [[ ! -f "$VENDOR/DeltaCore/Package.swift" ]]; then
  echo "Cloning DeltaCore…"
  git clone --depth 1 https://github.com/rileytestut/DeltaCore.git "$VENDOR/DeltaCore"
fi
if [[ -f "$VENDOR/DeltaCore/Package.swift" ]]; then
  sed -i '' 's/swift-tools-version:5.3/swift-tools-version:5.9/' "$VENDOR/DeltaCore/Package.swift" || true
  sed -i '' 's/\.iOS(\.v14)/.iOS(.v17)/' "$VENDOR/DeltaCore/Package.swift" || true
fi

clone_core() {
  local name="$1"
  local url="$2"
  local dest="$VENDOR/$name"
  if [[ -d "$dest/.git" ]]; then
    echo "Updating ${name}..."
    git -C "$dest" pull --ff-only || true
  else
    echo "Cloning ${name}..."
    git clone --depth 1 --recurse-submodules "$url" "$dest"
  fi
}

clone_core GBCDeltaCore https://github.com/rileytestut/GBCDeltaCore.git
clone_core GBADeltaCore https://github.com/rileytestut/GBADeltaCore.git
clone_core NESDeltaCore https://github.com/rileytestut/NESDeltaCore.git
clone_core SNESDeltaCore https://github.com/rileytestut/SNESDeltaCore.git
clone_core GPGXDeltaCore https://github.com/rileytestut/GPGXDeltaCore.git

cat <<'EOF'

Cores are under Vendor/. In Xcode:
1. DeltaCore is already linked via the local SPM package at Vendor/DeltaCore.
2. Add each Vendor/*/Xcode project (or drag the .xcodeproj) and link the matching framework to the PressStart target.
3. Rebuild. CoreRegistry registers cores via canImport when the modules are present.

Without these frameworks the app still builds; play shows a core-missing message.
EOF
