#!/usr/bin/env python3
"""Generate metronome click WAV fixtures for RPMBuddy QA and unit tests.

Synthesized sine clicks (similar to web metronome generators). Project-authored; treat as CC0.
"""
from __future__ import annotations

import json
import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44_100
CLICK_MS = 10
CLICK_FREQ = 1_000.0
CLICK_AMP = 0.9
DURATION_SECONDS = 30
BPMS = (50, 60, 80, 90, 100, 120, 128, 140, 145, 160)

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "Resources" / "Fixtures"


def write_metronome(path: Path, bpm: int, seconds: int) -> None:
    sample_count = SAMPLE_RATE * seconds
    samples = [0.0] * sample_count
    period = int(SAMPLE_RATE * 60.0 / bpm)
    click_len = max(1, int(SAMPLE_RATE * CLICK_MS / 1000.0))

    pos = 0
    while pos < sample_count:
        for index in range(click_len):
            if pos + index >= sample_count:
                break
            time = index / SAMPLE_RATE
            envelope = math.exp(-time * 70)
            samples[pos + index] = CLICK_AMP * envelope * math.sin(2 * math.pi * CLICK_FREQ * time)
        pos += period

    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SAMPLE_RATE)
        payload = b"".join(
            struct.pack("<h", max(-32_768, min(32_767, int(sample * 32_767)))) for sample in samples
        )
        handle.writeframes(payload)


def write_manifest(fixtures: list[dict]) -> None:
    manifest = {
        "description": "RPMBuddy metronome fixtures for analyzer verification",
        "fixtures": fixtures,
    }
    (OUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    entries: list[dict] = []
    generated_names: set[str] = set()
    for bpm in BPMS:
        filename = f"metronome-{bpm}bpm-{DURATION_SECONDS}s.wav"
        path = OUT_DIR / filename
        write_metronome(path, bpm, DURATION_SECONDS)
        generated_names.add(filename)
        entries.append(
            {
                "filename": filename,
                "expectedBPM": bpm,
                "durationSeconds": DURATION_SECONDS,
                "sampleRateHz": SAMPLE_RATE,
                "source": "Scripts/generate_metronome_fixture.py",
                "license": "Project-generated metronome clicks (CC0-equivalent)",
            }
        )
        print(f"Wrote {path} ({path.stat().st_size // 1024} KB)")

    manifest_path = OUT_DIR / "manifest.json"
    if manifest_path.exists():
        existing = json.loads(manifest_path.read_text(encoding="utf-8"))
        for fixture in existing.get("fixtures", []):
            filename = fixture.get("filename")
            if filename and filename not in generated_names:
                entries.append(fixture)

    write_manifest(entries)
    print(f"Wrote {manifest_path}")


if __name__ == "__main__":
    main()
