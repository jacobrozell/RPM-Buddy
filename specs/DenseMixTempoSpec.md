# Dense mix tempo detection — RPM Buddy

**Status:** Superseded 2026-11-01 by the librosa-style analyzer described in [BPMDetectorSpec](BPMDetectorSpec.md#analyzer)  
**Last updated:** 2026-06-22  
**Supersedes:** `docs/brainstorm-sensitivity.md` Option D (promoted)  
**Related:** [BPMDetectorSpec](BPMDetectorSpec.md), [ArchitectureSpec](ArchitectureSpec.md), `Tests/FacesAlbumAnalysisTests.swift`, `Tests/ILTYAlbumAnalysisTests.swift`

### v1.1 ship gate (local file analysis)

| Metric | Target | Result |
|--------|--------|--------|
| Faces reference tracks | 11 / 11 | **11 / 11** |
| Insomniak | ~120 BPM (±8) | **120 BPM** |
| Metronome fixtures (90, 120, 128) | pass | **pass** |
| ILLTY verification (5 tracks) | pass | **5 / 5** (title 93 BPM from DB; others regression-locked) |

---

## Problem

The v1.0 analyzer (broadband energy-difference onset + harmonic autocorrelation) works well on **metronome clicks** and many **steady drum loops**, but misreads **dense hip-hop / sample-heavy mixes** where hi-hats, vocals, and production swells dominate the onset envelope.

### Known failures (Mac Miller — *Faces*, file analysis baseline)

| Track | Expected | Detected (v1.0) | Failure mode |
|-------|----------|-----------------|--------------|
| **Insomniak** | ~120 BPM | ~80 BPM | **Subdivision lock** — 80 = 120 × ⅔ (triplet / swung grid); quarter-note pulse weak |
| **New Faces v2** | ~111 BPM | ~126 BPM | **Cluster pick** — competing peaks at 115–148 BPM; no clear winner at 111 |

These are **not** fixed by octave folding (half/double time). Diablo (~159 ≈ 2× 80) and Friends (~74 ≈ ½× 148) already pass with octave-aware matching.

### Design goal

Improve **root tempo** detection on dense mixes **without regressing** metronome accuracy or adding ML dependencies. Target v1.1:

| Metric | v1.0 baseline | v1.1 target |
|--------|---------------|-------------|
| Faces reference tracks passing | 9 / 11 | **11 / 11** |
| Insomniak | ~80 BPM | **114–126 BPM** (±8 of 120) |
| New Faces v2 | ~126 BPM | **103–119 BPM** (±8 of 111) |
| Metronome fixtures (90, 120, 128) | pass | **unchanged** |
| Analyzer CPU (12 s window, A15+) | baseline | **≤ 2× baseline** |

User-visible behavior, confidence meter, and tempo alternatives UI **unchanged** unless noted below.

---

## Root cause (technical)

1. **Onset source** — `max(0, energy[i] − energy[i−1])` on full-band STFT energy tracks **fastest transients** (hi-hats, claps, vocal consonants), not kick/downbeat.
2. **Lag-space scoring** — harmonic autocorrelation rewards **any** stable periodicity, including ⅔-rate grids (Insomniak) and near-neighbor tempos (New Faces).
3. **Single envelope** — one onset stream cannot disambiguate kick (80 BPM feel) from hi-hat (120 BPM subdivision).

---

## Proposed solution — multi-band onset + BPM comb scoring

Replace the single broadband onset path with a **weighted multi-band pipeline**, then score **integer BPM candidates directly** instead of picking a raw autocorrelation lag first.

### Pipeline (v1.1)

```
mono PCM (11,025 Hz effective)
    ↓
short-time frames (window 512, hop 128) — unchanged
    ↓
per-band spectral flux onset (3 bands)
    ↓
weighted fusion → combined onset envelope
    ↓
BPM comb score for each integer BPM in 70…180
    ↓
octave-aware candidate pick + parabolic refine
    ↓
BPMEstimate(bpm, confidence)
```

All steps stay in `BPMAnalyzer` (pure Swift, no AVFoundation).

---

## 1. Multi-band spectral flux onset

### Bands

| Band | Hz (approx) | Role | Weight |
|------|-------------|------|--------|
| **Low** | 20–150 | Kick / sub pulse | **0.55** |
| **Mid** | 150–2,000 | Snare / body | **0.30** |
| **High** | 2,000–5,500 | Hi-hats (de-emphasized) | **0.15** |

Weights apply to **fused** onset envelope. Tunable constants in one private enum; no user setting in v1.1.

### Per-frame flux

For each band and frame index `i`:

```
flux[i] = max(0, bandEnergy[i] − bandEnergy[i − 1])
```

Apply **half-wave rectification** and subtract band mean (same as today). Band energy from **Goertzel bank** or lightweight DFT magnitude sum over bin range — prefer Goertzel at band edges if CPU allows; otherwise sum squared FFT bins from existing frame window.

### Fusion

```
onset[i] = wLow * lowFlux[i] + wMid * midFlux[i] + wHigh * highFlux[i]
```

Then mean-center the fused envelope (current behavior).

**Rationale:** Insomniak’s erroneous 80 BPM lock correlates with hi-hat/mid transient periodicity; down-weighting high band and boosting low band should strengthen the 120 BPM kick grid.

---

## 2. BPM-space comb scoring (replace lag-first pick)

Instead of `bestHarmonicLag` → convert lag to BPM, **score each candidate BPM directly**:

For each integer `bpm` in 70…180:

```
periodFrames = 60 × framesPerSecond / bpm
score(bpm) = Σᵢ comb(onset, i, periodFrames)
```

Where `comb` sums fused onset at `i`, `i − period`, `i − 2×period`, … up to 4 pulses, using **linear interpolation** for fractional frame indices (reuse parabolic neighbor logic).

### Harmonic enrichment (octave)

```
total(bpm) = score(bpm)
           + 0.5 × score(2×bpm)   if 2×bpm ≤ 180
           + 0.25 × score(4×bpm)  if 4×bpm ≤ 180
           + 0.5 × score(bpm/2)   if bpm/2 ≥ 70
```

Pick `argmax total(bpm)`. Refine with **±0.5 BPM** parabolic fit on the top three integer candidates.

**Rationale:** Direct BPM scoring makes octave relationships explicit. Beats lag-first conversion error for metronome (already fixed via effective sample rate).

---

## 3. Subdivision disambiguation (Insomniak class)

When top two BPM candidates `b1`, `b2` have scores within **8%** of each other and their ratio is near a **simple fraction**:

| Ratio (b1/b2) | Interpretation | Prefer |
|---------------|----------------|--------|
| ~1.50 (3:2) | Triplet / swung subdivision | **Higher BPM** (musical tactus) |
| ~1.33 (4:3) | Dotted subdivision | **Higher BPM** |
| ~2.00 | Octave | Existing fold rules |
| ~0.67 | Inverse 3:2 | **Higher BPM** |

Implementation:

```
if abs(b1/b2 − 1.5) < 0.06 && score(b2) > 0.92 × score(b1) {
    chosen = max(b1, b2)
}
```

Only apply when **both** candidates are in 70–180 after fold. Log internally in `#if DEBUG` for tuning.

**Rationale:** Insomniak: 120 vs 80 = 1.5 exactly. Preferring the faster tactus when scores are close addresses the specific failure without ML.

---

## 4. Confidence (adjust semantics slightly)

Keep 0…1 range and existing UI thresholds. Recompute from comb scores:

| Component | Weight | Notes |
|-----------|--------|-------|
| Peak ratio (1st vs 2nd BPM) | 0.40 | Same intent as today |
| Normalized peak score | 0.35 | `bestScore / theoreticalMax` |
| Signal level (RMS) | 0.25 | Unchanged |

Do **not** lower the 0.08 / 0.12 display gates in this spec — better peaks should raise confidence naturally on Insomniak.

---

## 5. Integration

### Files

| File | Change |
|------|--------|
| `Sources/Domain/BPMAnalyzer.swift` | Multi-band flux, comb scoring, subdivision rule |
| `Sources/Domain/BPMAnalyzer.swift` | Keep `prepareSamples`, `effectiveSampleRate`, public API |
| `Sources/Features/Detector/DetectorViewModel.swift` | **No change** |
| `Sources/Data/FileBPMEstimator.swift` | **No change** |

### Performance budget

- 12 s window @ 11,025 Hz → ~720 onset frames
- 111 BPM candidates × 720 frames × 4 comb taps ≈ 320k ops — acceptable on device
- If profiling exceeds 2×: reduce to **0.5 BPM steps** only near top 5 integer candidates

### Feature flag (dev only)

```swift
enum BPMAnalyzer {
    static var useDenseMixPipeline = true  // DEBUG toggle; always true in Release once verified
}
```

Allows A/B in unit tests without a Settings UI.

---

## 6. Verification

### Automated

| Suite | Requirement |
|-------|-------------|
| `BPMAnalyzerTests` | All existing tests pass |
| `MetronomeFixtureTests` | All fixtures pass (±6 BPM) |
| `FacesAlbumAnalysisTests` | **11/11** reference tracks pass (octave-aware) |
| `FacesAlbumAnalysisTests/insomniakNear120` | **Hard expect** ±8 of 120 (remove warning-only) |
| New: `DenseMixAnalyzerTests` | Synthetic 120 BPM kick+hat mix where hat is ⅔ grid → must return 118–122 |

### Synthetic torture test (CI-safe)

Generate in `BPMAnalyzerTests`:

- **120 BPM kick** (sine burst 60 Hz, every 0.5 s)
- **Overlaid 180 BPM hi-hat** (short noise bursts) — simulates subdivision confusion
- Pass: primary BPM 114–126

### Manual

```bash
bash Scripts/analyze-local-album.sh
```

Confirm Insomniak and New Faces lines show pass in report.

---

## 7. Out of scope (v1.1)

- Core ML / Essentia / external DSP libraries
- Variable tempo / rubato detection
- Changing plausible range (70–180) or tempo alternatives UI
- Bundling Faces MP3s in repo
- Mic-path-only preprocessing (AGC) — separate track in sensitivity brainstorm

---

## 8. Rollout

| Phase | Deliverable |
|-------|-------------|
| **1** | Multi-band flux + fused envelope; keep lag autocorrelation — validate Insomniak improves in isolation |
| **2** | BPM comb scoring replaces lag-first pick |
| **3** | Subdivision disambiguation + synthetic torture tests |
| **4** | Remove DEBUG flag; update `BPMDetectorSpec` verification table; mark this spec **shipped** |

---

## 9. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Regress metronome | MetronomeFixtureTests + click-track unit tests gate every phase |
| Over-favor fast tempos | Subdivision rule only when scores within 8% **and** ratio ≈ 3:2 or 4:3 |
| CPU on older devices | Profile 12 s window on iPhone 12; cap comb taps |
| False confidence on noise | Keep RMS gate; normalization unchanged |

---

## 10. Success criteria (ship gate)

- [ ] Insomniak file analysis: 112–128 BPM, confidence ≥ 0.12  
- [ ] New Faces file analysis: 103–119 BPM, confidence ≥ 0.12  
- [ ] Metronome self-test in Settings: all pass  
- [ ] Faces verification: 11/11 reference tracks  
- [ ] No increase in silent-room false BPM (silence test still nil)

---

## References

- Failure analysis: conversation 2026-06-22 (Insomniak 80 = 120 × ⅔; New Faces peak cluster)  
- Baseline tests: `Tests/FacesAlbumAnalysisTests.swift`, `Tests/Support/FacesAlbumCatalog.swift`  
- Prior art: MixStack `AudioAnalyzer.estimateBPM` (same family; RPM Buddy v1.1 diverges with multi-band + comb)
