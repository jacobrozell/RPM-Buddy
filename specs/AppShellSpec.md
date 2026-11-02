# App shell spec — RPM Buddy

## Navigation

- Root shows mic onboarding until record permission is **granted**.
- After grant: single `DetectorView` with settings sheet.
- Portrait only on iPhone; iPad portrait (+ upside down).

## Onboarding

- Explain on-device listening; one **Allow microphone** button.
- If denied, show Settings hint; no forced deep link.

## Settings

- Version row
- Support, Privacy, Accessibility links via `AppLinks`
- Disclaimer that estimates are not metronome-grade

## Launch arguments (tests)

| Flag | Effect |
|------|--------|
| `-ui_test_skip_mic_onboarding` | Skip permission gate |
| `-ui_test_mock_bpm <n>` | Mock stable BPM, no mic |

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0 |
| Last verified | 2026-06-21 |
| Primary paths | `Sources/Views/RootView.swift`, `Sources/Features/Onboarding/MicPermissionView.swift`, `Sources/Features/Settings/SettingsView.swift` |
