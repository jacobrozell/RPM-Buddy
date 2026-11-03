#!/usr/bin/env bash
# Sync metronome test fixtures: generate labeled clicks + optional BigSoundBank CC0 sample.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURES="${ROOT}/Resources/Fixtures"
BSB_MP3_URL="https://bigsoundbank.com/UPLOAD/mp3/0468.mp3"
BSB_MP3="${FIXTURES}/.download-0468.mp3"
BSB_FILE="${FIXTURES}/metronome-bigsoundbank-120bpm-12s.wav"

cd "${ROOT}"
python3 Scripts/generate_metronome_fixture.py

echo "::group::Download BigSoundBank CC0 mechanical metronome (~120 BPM)"
mkdir -p "${FIXTURES}"
curl -fsSL -A "RPMBuddy-fixture-sync/1.0" "${BSB_MP3_URL}" -o "${BSB_MP3}"
afconvert -f WAVE -d LEI16 "${BSB_MP3}" "${BSB_FILE}"
rm -f "${BSB_MP3}"
echo "Downloaded and converted ${BSB_FILE} ($(du -h "${BSB_FILE}" | cut -f1))"
echo "::endgroup::"

python3 - <<'PY'
import json
from pathlib import Path

fixtures_dir = Path("Resources/Fixtures")
manifest_path = fixtures_dir / "manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
entry = {
    "filename": "metronome-bigsoundbank-120bpm-12s.wav",
    "expectedBPM": 120,
    "durationSeconds": 12,
    "sampleRateHz": 48000,
    "source": "BigSoundBank sound #0468 (Joseph SARDIN)",
    "license": "CC0 — https://bigsoundbank.com/metronome-a-120bpm-s0468.html",
    "notes": "Recorded mechanical metronome; approximate tempo.",
}
fixtures = [item for item in manifest["fixtures"] if item.get("filename") != entry["filename"]]
fixtures.append(entry)
manifest["fixtures"] = fixtures
manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print("Updated manifest.json with BigSoundBank entry")
PY

echo "✅ Metronome fixtures ready in Resources/Fixtures/"
