# BPM detector spec — RPM Buddy

## User-visible behavior

1. User taps **Listen** → app starts microphone capture.
2. While listening, show:
   - **BPM** — large numeric estimate, or em dash when unknown
   - **Logged reading** — once tempo stabilizes, record timestamp (medium date + time) and keep visible after Stop
   - **Tempo alternatives** — half-time, primary, double-time (and quarter-time when in range) for the same pulse
   - **Confidence meter** — 0–100% linear gauge with short caption
   - **Input level** — bar reflecting mic energy (confirms the mic is working)
3. User taps **Stop** → capture stops; last logged reading, timestamp, and alternatives remain on screen.
4. Status footnote updates for idle, listening, quiet signal, and estimating states.
5. **Tap the beat** — tap in time with the music. After three taps, the displayed count snaps to the microphone tempo's quarter, half, primary, or double that matches those taps, and the BPM card flashes on that beat. The last tap is the downbeat. If the mic has no tempo, the count comes from the taps alone. Starting Listen clears the sync.
6. **Too slow / Too fast** — once a tempo is showing, these lock the next faster or slower count in that same family (160 → 80 → 40, and back). The mic cannot pull the count back. Tap the beat while locked only moves the downbeat. Listen clears the lock. A count that came from taps stays a tap count, so the mic confidence meter stays hidden. While listening, the phone ticks a light haptic on each beat. The speaker stays silent so the click cannot leak into the mic.

## Confidence semantics

- Derived from how periodic the onset envelope is at the chosen beat (normalized autocorrelation). Pure room noise scores near 0; clear grooves reach 100%.
- **Low** (< 15%): do not show a BPM number.
- Meter tint: orange / yellow / green by band (non-color labels still describe level).
- VoiceOver reads confidence as a percentage.

## Analyzer

Follows librosa's `beat.tempo` (ISC): log-compressed mel spectral flux, 8 s autocorrelation windows averaged over time, a log-normal prior centered on 120 BPM, and a comb over the first four multiples of each candidate period. Pure Swift + Accelerate, no third-party code.

## Analysis limits

- Plausible BPM range: 70–180 (octave folding applied).
- Not marketed as studio-grade; settings disclaimer required.

## Accessibility

- All primary controls have `accessibilityIdentifier`s (see `A11yID`).
- BPM and confidence are readable without seeing color alone.

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0 |
| Last verified | 2026-06-21 |
| Tests | `Tests/BPMAnalyzerTests.swift`, `Tests/TapBeatSyncTests.swift`, `RPMBuddyUITests/SmokeUITests.swift` |
| Primary paths | `Sources/Features/Detector/*`, `Sources/Domain/BPMAnalyzer.swift` |
