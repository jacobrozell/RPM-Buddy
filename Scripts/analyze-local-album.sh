#!/usr/bin/env bash
# Analyze BPM for locally owned audio files (development only — not bundled).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

ALBUM_DIR="${1:-${ROOT}/local-test-media/Mac Miller - Faces}"
if [[ ! -d "${ALBUM_DIR}" ]]; then
  ALBUM_DIR="${ROOT}/local-test-media/albums/Mac Miller - Faces"
fi
if [[ ! -d "${ALBUM_DIR}" ]]; then
  ALBUM_DIR="${ROOT}/local-test-media/I Love Life Thank You"
fi
if [[ ! -d "${ALBUM_DIR}" ]]; then
  ALBUM_DIR="${ROOT}/Mac Miller - Faces"
fi
if [[ ! -d "${ALBUM_DIR}" ]]; then
  echo "error: Album folder not found: ${ALBUM_DIR}" >&2
  echo "Usage: $0 [/path/to/album]" >&2
  exit 1
fi

if [[ ! -f Resources/Fixtures/metronome-120bpm-30s.wav ]]; then
  bash Scripts/sync-metronome-fixtures.sh
fi

xcodegen generate

export RPMBUDDY_LOCAL_AUDIO_DIR="${ALBUM_DIR}"

echo "Analyzing audio in: ${ALBUM_DIR}"
echo ""

xcodebuild test \
  -project RPMBuddy.xcodeproj \
  -scheme RPMBuddyCI \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath DerivedData \
  -only-testing:RPMBuddyTests/FacesAlbumAnalysisTests \
  -only-testing:RPMBuddyTests/ILTYAlbumAnalysisTests \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tee /tmp/rpmbuddy-local-album.log | rg 'Faces |Summary|✔|✘|Issue|error:|TEST SUCCEEDED|TEST FAILED' || true

echo ""
echo "Full log: /tmp/rpmbuddy-local-album.log"
