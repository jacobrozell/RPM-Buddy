# Brainstorm — quiet / distant listening sensitivity

**Last updated:** 2026-06-21  
**Status:** Non-authoritative brainstorm → promote to `specs/` when approach is chosen.

**Problem:** RPM Buddy only locks tempo when the source is **very loud** (speaker cranked, phone close). Normal room listening (laptop, vinyl across the room, Mac Miller album at moderate volume) often shows no BPM or low confidence.

---

## What works today vs what fails

| Source | Works? | Why |
|--------|--------|-----|
| Bundled metronome WAV | ✅ | Sharp clicks, full digital scale, long window |
| File analysis (Faces MP3) | ✅ | Full file level, no mic loss |
| Mic + loud speaker | ✅ | Enough RMS to pass gates |
| Mic + moderate room volume | ❌ | Multiple stacked thresholds reject or hide BPM |

File path proves the **analyzer can** hear the music; the gap is **mic capture level + gating**, not necessarily a wrong BPM algorithm.

---

## Root causes (current code)

### 1. Hard RMS silence gate
`BPMAnalyzer` aborts if `rms <= 0.002` — fine for synthetic tests, harsh for real mic at distance.

### 2. No gain staging before analysis
Live samples use raw tap floats (~0.01–0.05 RMS typical at moderate volume). Metronome fixtures sit near full scale after generation.

### 3. Confidence punishes quiet level
`levelFactor = min(1, rms * 40)` — at RMS 0.01, levelFactor ≈ 0.4, dragging confidence down even when beat pattern is clear.

### 4. UI double gate
- Analyzer hides BPM when `confidence < 0.08`
- ViewModel smoothing/logging requires `confidence >= 0.15`
- Status says "quiet" when `inputLevel < 0.03` (meter uses arbitrary `rms * 8`)

### 5. Onset detector favors sharp transients
Energy-difference onset envelope works for clicks/metronome; **hip-hop / dense mixes** (e.g. Faces) have smeared onsets at low mic SNR.

### 6. Session / hardware
`.measurement` mode = flat, no Apple voice processing boost. iPhone mic rolloff + distance = weak kick/snare in envelope.

### 7. Analysis window
12 s rolling buffer is OK for metronome; sparse intros or long ambient passages delay stable autocorrelation.

---

## Option matrix

| Approach | Effort | Impact | Risk |
|----------|--------|--------|------|
| **A. Adaptive normalize before analyze** | Low | High | Boosts noise in silent rooms → need noise floor |
| **B. Lower RMS / confidence gates** | Low | Medium | False positives on noise |
| **C. AGC in capture pipeline** | Medium | High | Pumping artifacts; must cap max gain |
| **D. Spectral-flux / band-pass onset** | Medium | High for bass-heavy music | More CPU; needs tests |
| **E. Longer analysis window (20–30 s)** | Low | Medium | Slower time-to-first-BPM |
| **F. User “sensitivity” setting** | Medium | UX clarity | Still need better default |
| **G. Tap tempo fallback** | Medium | Covers failure mode | Different feature |
| **H. Import file / Apple Music** | High | Bypasses mic entirely | Scope + licensing |

**Recommended v1.1 stack:** **A + C (capped) + B (tuned) + E**, then **D** if Faces-style tracks still struggle.

---

## Proposed default behavior (v1.1)

1. **Measure** RMS of analysis window; if above noise floor, apply gain toward target RMS (cap e.g. 40×).
2. **Show** raw input level on meter (honest), analyze on normalized copy ( sensitive).
3. **Separate** “signal present” from “tempo confident” in copy:
   - Hearing audio but low confidence → “Beat unclear — try louder or closer”
   - No signal → “Very quiet — move closer”
4. **Log** only when confidence ≥ 0.12 after normalization (tune with Faces album).
5. **Settings → Sensitivity:** Normal / Boost (higher max gain) for v1.2.

---

## Test plan (Faces + metronome)

| Case | Pass |
|------|------|
| Metronome 120 @ full scale | 114–126 BPM, confidence > 0.2 |
| Metronome 120 @ −20 dB (scaled) | Still detects after normalize |
| Faces track file (Insomniak, Diablo) | BPM within ±8 or honest low confidence |
| Mic @ moderate MacBook volume, 30 cm | Logs within 15 s |
| Silent room | No BPM, confidence ~0 |

Run: `bash Scripts/analyze-local-album.sh "Mac Miller - Faces"` before/after changes.

---

## Not in scope

- Bundling owned music
- Claiming studio-grade BPM
- Replacing autocorrelation with ML model (future idea)

---

## Next steps

1. ✅ Implement adaptive normalization (Phase 1 — see commit)
2. Re-test Faces album + device at moderate volume
3. If still weak: spectral-flux onset prototype behind flag
4. Promote chosen behavior to `specs/BPMDetectorSpec.md`
