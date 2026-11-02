# Contributing

See [`README.md`](README.md) for setup. Run `xcodegen generate` after editing `project.yml`.

## Layout

- `Sources/Domain/` — pure tempo analysis (`BPMAnalyzer`)
- `Sources/Data/` — microphone capture
- `Sources/Features/` — SwiftUI flows (detector, onboarding, settings)
- `Sources/DesignSystem/` — shared UI components
- `Sources/Support/` — launch configuration, links, accessibility IDs, logging, Firebase bootstrap
- `Tests/` — Swift Testing unit tests
- `RPMBuddyUITests/` — UI smoke tests (mock BPM launch args)

## Style

- 4-space indent, `private` by default
- Domain code must not import SwiftUI
- SwiftLint via `.swiftlint.yml` (CI enforces)
- **Never** commit or bundle personal audio (`*.mp3`, etc.); use `local-test-media/` or gitignored album folders for QA

## UI test launch args

- `-ui_test_skip_mic_onboarding` — opens detector without permission sheet
- `-ui_test_mock_bpm 120` — simulates a stable 120 BPM reading
- `-ui_test_reset` — disables Firebase Analytics and Crashlytics

Copy `Resources/GoogleService-Info.plist.example` to `Resources/GoogleService-Info.plist` for local builds. Replace placeholders from the Firebase console before a Release archive. Never commit the real plist.
