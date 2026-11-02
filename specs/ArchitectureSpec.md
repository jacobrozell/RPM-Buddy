# Architecture spec — RPM Buddy

## Layers

```
Features (SwiftUI + @Observable ViewModels)
    ↓
Domain (BPMAnalyzer — pure Swift)
    ↓
Data (LiveAudioCapture — AVFoundation)
```

- Domain never imports SwiftUI or AVFoundation.
- ViewModels run on `@MainActor`; analysis runs on cooperative thread pool via `Task`.

## Analysis pipeline

1. `LiveAudioCapture` fills a ring buffer at device sample rate (mono downmix).
2. Every ~900 ms, `DetectorViewModel` pulls the last 12 s window.
3. `BPMAnalyzer.prepareSamples` decimates toward 11,025 Hz.
4. `BPMAnalyzer.estimate` returns `BPMEstimate(bpm:confidence:)`.
5. ViewModel median-smooths recent BPM readings when confidence ≥ 0.15.

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0 |
| Last verified | 2026-06-21 |
| Primary paths | `Sources/Domain/BPMAnalyzer.swift`, `Sources/Data/LiveAudioCapture.swift`, `Sources/Features/Detector/DetectorViewModel.swift` |
