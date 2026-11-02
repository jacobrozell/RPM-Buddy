# Local test media (not shipped)

Put **personally owned** albums here for RPM Buddy development QA. Nothing in this tree is bundled in the app or committed to git.

## Layout

```
local-test-media/
  README.md                 ← this file (committed)
  Mac Miller - Faces/       ← gitignored — drop albums here
    *.mp3
  I Love Life Thank You/    ← gitignored — second local regression album
    *.mp3
  albums/                   ← also supported (gitignored)
    …
```

## Manual mic test

1. Play a track on a speaker (or AirPlay to a device near the phone).
2. Open RPM Buddy → **Listen** and hold the mic toward the speaker.
3. Compare logged BPM + confidence against your known track tempo (if any).

## Batch file analysis (DEBUG, local only)

Analyzes files on disk through the same `FileBPMEstimator` path as Settings verification — **no mic**, no bundling:

```bash
# Default: local-test-media/Mac Miller - Faces (if present)
bash Scripts/analyze-local-album.sh

# Or any folder of MP3/M4A/WAV you own
bash Scripts/analyze-local-album.sh "/path/to/your/album"
```

Requires a prior build. Results print to the terminal; nothing is uploaded or embedded in the app.

### Faces regression tests

When `local-test-media/Mac Miller - Faces/` exists, run:

```bash
xcodebuild test -project RPMBuddy.xcodeproj -scheme RPMBuddyCI \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:RPMBuddyTests/FacesAlbumAnalysisTests
```

Or use the analyze script above (same test suites). Tests skip silently in CI when album folders are absent.

### I Love Life, Thank You regression tests

When `local-test-media/I Love Life Thank You/` exists:

```bash
xcodebuild test -project RPMBuddy.xcodeproj -scheme RPMBuddyCI \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:RPMBuddyTests/ILTYAlbumAnalysisTests
```

## Release rule

- **Never** add these files to `Resources/`, `project.yml`, or Copy Bundle Resources.
- **Never** commit MP3/M4A/FLAC from this folder (pre-commit hook blocks them).
- Shippable fixtures stay in `Resources/Fixtures/` (metronome WAVs only).
