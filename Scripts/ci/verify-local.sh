#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT}"

if [[ ! -f Resources/Fixtures/metronome-120bpm-30s.wav ]]; then
  echo "Syncing metronome fixtures…"
  bash Scripts/sync-metronome-fixtures.sh
fi

if [[ ! -f Resources/GoogleService-Info.plist ]]; then
  cp Resources/GoogleService-Info.plist.example Resources/GoogleService-Info.plist
fi

xcodegen generate
swiftlint --strict

echo "Running RPMBuddyCI on iPhone 17 simulator…"
xcodebuild test \
  -project RPMBuddy.xcodeproj \
  -scheme RPMBuddyCI \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath DerivedData \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

echo "✅ RPMBuddy verification passed."
