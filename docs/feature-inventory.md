# Feature inventory — RPM Buddy

**Last updated:** 2026-11-02

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
| GA4 / Firebase Analytics + logging | ✅ v1 | [LoggingAnalyticsSpec](../specs/LoggingAnalyticsSpec.md) |
| Previous scans | ✅ v1 | Last eight readings, stored on the phone |
| Tap the beat | ✅ v1 | Snaps the count to your taps and flashes on that beat |
| Too slow / Too fast | ✅ v1 | Locks the next count in the same pulse family; haptic tick while listening |

## Release surface

v1 exposes the detector flow and settings. No accounts and no IAP. Release builds with a real Firebase plist send an allowlisted GA4 event set. Audio stays on device.
