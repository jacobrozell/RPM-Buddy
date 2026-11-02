# Future ideas

## Tempo engine → Swift Package (post–TestFlight)

After RPM Buddy TestFlight validates the detector on real devices, extract the analysis core into a **local SPM package** (working name: **TempoKit** or **RPMBuddyEngine**). RPM Buddy stays the live-listening app; other apps (starting with **Studio Buddy**) depend on the package for file-based BPM.

| In the package | Stays in RPM Buddy app |
|----------------|----------------------|
| `BPMAnalyzer`, `BPMEstimate`, dense-mix pipeline | `LiveAudioCapture`, mic permission, detector UI |
| `AudioLevelNormalizer` | Confidence meter, tempo-alternative chips, settings |
| `TempoInterpretations` (math only — no localized labels) | Onboarding, legal links, metronome self-test UI |
| `AudioFileLoader` / file estimator | — |

**Sequencing:** TestFlight + device QA → refactor/split `BPMAnalyzer` → SPM target → RPM Buddy depends on package → Studio Buddy adopts for import BPM → open-source the package (MIT, metronome fixture tests, accuracy disclaimer).

**Consumer:** [`Studio Buddy`](../../StudioBuddy/FutureIdeas/backlog.md) replaces `AudioAnalyzer.estimateBPM` with the shared estimator; key + vocal detection remain in Studio Buddy.

---

## Product (RPM Buddy app)

- Session history (last N readings with timestamp)
- Spectral-flux onset for bass-heavy / hip-hop mic pickup (see `docs/brainstorm-sensitivity.md`)
- Settings sensitivity toggle (Normal / Boost max gain)
- Haptic pulse at detected BPM
- Widget / Lock Screen live activity
- Localized String Catalog pass
- Streaming mic API on the package (optional) — feed live buffers from `DetectorViewModel` through a public `TempoAnalyzer` surface
