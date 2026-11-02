# RPM Buddy

A minimal iOS app that listens through the microphone, estimates the tempo of nearby music, and shows how trustworthy the analysis is via a confidence meter.

**Status:** v1 complete · **Bundle:** `com.jacobrozell.rpmbuddy` · **Min iOS:** 18.0 · Pre-ship polish

Product specs live in [`specs/`](specs/README.md). Shipped vs planned features: [`docs/feature-inventory.md`](docs/feature-inventory.md).

---

## What it does

- **Live BPM detection** — real-time tempo analysis from the mic with logged readings and timestamps
- **Half/double-time alternatives** — tap to switch when the detector locks to a related tempo
- **Tap the beat** — tap along to pick the count and flash a pulse on your downbeat
- **Too slow / Too fast** — lock the next count when the pulse feels rushed or dragged
- **Confidence meter** — visual trust indicator for the current reading
- **Input level meter** — see when the mic is picking up signal
- **Mic permission onboarding** — first-run explanation before capture starts
- **Metronome self-test** — bundled WAV fixtures + in-app verification (Settings → Run metronome verification)
- **Settings** — legal links; no accounts or IAP

**Planned (post-v1):** session history — see feature inventory.

---

## Build & run

Requires **Xcode 16+** and **iOS 18+**. The Xcode project is generated from `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen   # once
xcodegen generate
open RPMBuddy.xcodeproj
```

Select an iPhone simulator (or device) and press **⌘R**. Signing uses team `7JT2JB89AV`.

---

## Tests & CI

Sync metronome fixtures once (or let CI/`verify-local.sh` do it), then run tests:

```bash
bash Scripts/sync-metronome-fixtures.sh
xcodegen generate
bash Scripts/ci/verify-local.sh
```

| Gate | What runs |
|------|-----------|
| **PR CI** | SwiftLint + `RPMBuddyCI` unit tests on iPhone 17 simulator |

Unit tests analyze bundled metronome WAVs. UI smoke tests use `-ui_test_mock_bpm 120` because the simulator mic is unreliable.

---

## Architecture

| Layer | Role |
|-------|------|
| `Sources/Features/` | SwiftUI screens — detector, settings, onboarding |
| `Sources/Domain/` | `BPMAnalyzer`, tempo interpretation, confidence math |
| `Sources/Support/` | Audio session, permissions, app links |

The BPM engine is pure Swift — no SwiftUI imports — so core analysis is fully unit-testable. See [`specs/ArchitectureSpec.md`](specs/ArchitectureSpec.md).

---

## Documentation map

| Topic | Location |
|-------|----------|
| Agent build phases | [`docs/agent-build-checklist.md`](docs/agent-build-checklist.md) |
| What ships today | [`docs/feature-inventory.md`](docs/feature-inventory.md) |
| BPM detector spec | [`specs/BPMDetectorSpec.md`](specs/BPMDetectorSpec.md) |
| Analytics and logging | [`specs/LoggingAnalyticsSpec.md`](specs/LoggingAnalyticsSpec.md) |
| App shell spec | [`specs/AppShellSpec.md`](specs/AppShellSpec.md) |
| Metronome fixtures | [`Resources/Fixtures/README.md`](Resources/Fixtures/README.md) |
| Contributing | [`CONTRIBUTING.md`](CONTRIBUTING.md) |

---

## Defaults (v1)

| Setting | Value |
|---------|-------|
| **Name** | RPM Buddy |
| **Bundle** | `com.jacobrozell.rpmbuddy` |
| **Min iOS** | 18.0 |
| **Locale** | English |
| **Orientation** | Portrait |
| **Telemetry** | GA4 via Firebase Analytics in Release; off in Debug |
| **Tip jar** | None |
