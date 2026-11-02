# Feature inventory — RPM Buddy

**Last updated:** 2026-06-21

| Feature | Status | Spec |
|---------|--------|------|
| Live BPM detection | ✅ v1 | [BPMDetectorSpec](../specs/BPMDetectorSpec.md) |
| Logged reading + timestamp | ✅ v1 | [BPMDetectorSpec](../specs/BPMDetectorSpec.md) |
| Half/double-time alternatives | ✅ v1 | [BPMDetectorSpec](../specs/BPMDetectorSpec.md) |
| Metronome fixtures + self-test | ✅ v1 | [`Resources/Fixtures/README.md`](../Resources/Fixtures/README.md) |
| Confidence meter | ✅ v1 | [BPMDetectorSpec](../specs/BPMDetectorSpec.md) |
| Input level meter | ✅ v1 | [BPMDetectorSpec](../specs/BPMDetectorSpec.md) |
| Mic permission onboarding | ✅ v1 | [AppShellSpec](../specs/AppShellSpec.md) |
| Settings + legal links | ✅ v1 | [AppShellSpec](../specs/AppShellSpec.md) |
| Session history | ⛔ planned | FutureIdeas |
| Tap tempo | ⛔ planned | FutureIdeas |

## Release surface

v1 exposes only the detector flow and settings. No accounts, no analytics, no IAP.
