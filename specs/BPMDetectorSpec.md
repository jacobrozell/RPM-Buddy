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
| Tests | `Tests/BPMAnalyzerTests.swift`, `RPMBuddyUITests/SmokeUITests.swift` |
| Primary paths | `Sources/Features/Detector/*`, `Sources/Domain/BPMAnalyzer.swift` |
