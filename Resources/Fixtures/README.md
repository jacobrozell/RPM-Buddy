# Metronome test fixtures

Labeled WAV files for RPM Buddy analyzer verification and manual QA.

## Refresh fixtures

```bash
bash Scripts/sync-metronome-fixtures.sh
```

This:

1. Generates **50 / 60 / 80 / 90 / 100 / 120 / 128 / 140 / 145 / 160 BPM** sine-click metronomes (30 s, mono 44.1 kHz) via `Scripts/generate_metronome_fixture.py` — project-authored, CC0-equivalent.
2. Downloads **BigSoundBank #0468** mechanical metronome (~120 BPM, 12 s, CC0).

See `manifest.json` for expected BPM per file.

## Manual app check (device or Mac speaker)

1. Build and run RPM Buddy on a device (or simulator with audio routed to mic).
2. Open **Settings → Verification → Run 120 BPM metronome test** (analyzes bundled file directly).
3. Or play `metronome-120bpm-30s.wav` on a speaker near the phone and tap **Listen**.

Pass: primary BPM within ±6 of labeled tempo; confidence clearly above low band.

## Tests

`Tests/MetronomeFixtureTests.swift` loads each bundled WAV through `FileBPMEstimator` (same path as mic analysis after decode).

## Owned albums (never bundled)

Personal MP3s (e.g. **Mac Miller — Faces** at repo root) are **gitignored**. Batch-analyze on disk:

```bash
bash Scripts/analyze-local-album.sh "Mac Miller - Faces"
```

See [`local-test-media/README.md`](../../local-test-media/README.md).
