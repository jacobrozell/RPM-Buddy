# Polish backlog — RPM Buddy

**Last updated:** 2026-06-21

Prioritized polish from MVP review. Legend: **ship** = TestFlight/App Store gate · **UX** = core product · **visual** = feel · **trust** = confidence/transparency differentiator · **post-v1** = defer.

---

## Ship blockers (before TestFlight)

| Item | Phase | Notes |
|------|-------|-------|
| App icon + launch screen | 16 | Placeholder asset catalog today |
| Legal pages live | 15 | `AppLinks` → `jacobrozell.github.io/RPM-Buddy/*` not deployed |
| Device QA with real music | 16 | Simulator mic is unreliable; vinyl, speaker, Bluetooth, quiet rooms |
| VoiceOver walkthrough | 11 | Identifiers exist; no manual sign-off |
| Dynamic Type at AXXXL | 11 | 72pt BPM + chip row may clip |

---

## High-leverage UX

| Item | Why |
|------|-----|
| **Tap alternative to promote** | Shipped as Too slow / Too fast, which lock the next count in the family |
| **Lock reading button** | Explicit save when user agrees; not only auto-log on stability |
| **Session history (last 5–10)** | Timestamp + alternatives already exist; list is natural next step |
| **Tap tempo fallback** | Shipped: Tap the beat snaps the octave and flashes on the downbeat |
| **Haptic pulse at BPM** | Shipped. The tick schedule is unit-tested; UI tests skip the live loop. |
| **Clear listening states** | Distinct UI: waiting / hearing / analyzing / logged (not just footnote) |
| **Signal-guided copy** | Tie input level to “move closer,” “try the chorus,” etc. |

---

## Trust & transparency

| Item | Why |
|------|-----|
| Plain-language confidence | “Strong beat pattern” vs “Weak or irregular pulse,” not only % |
| Explain alternatives | One line: detectors count every beat or every other beat |
| Raw vs smoothed toggle | Power users see live estimate vs locked median |
| Settings disclaimer expansion | Vinyl noise, live drums, double-time genres (D&B, punk) |

---

## Visual polish

| Item | Why |
|------|-----|
| Beat-synced pulse ring | Tied to input level / tempo; respect Reduce Motion |
| Dark mode contrast audit | Confidence tints + chip materials |
| Empty state illustration | Mic + speaker hint before first Listen |
| Stop → summary card | Frozen last reading + share |

---

## Technical polish

| Item | Why |
|------|-----|
| Persist last reading | `UserDefaults` / SwiftData — reopen shows last log |
| Share sheet | Text or image card (“128 BPM · logged …”) |
| Background / interrupt handling | Pause on call/background; clear UI on return |
| Localization pass | Migrate strings to `Localizable.xcstrings` |
| Spec drift script | CI gate per checklist Phase 1 |

---

## Suggested implementation order

1. App icon + legal pages  
2. Device QA → fix analyzer edge cases (use [`test-audio-sources.md`](test-audio-sources.md))  
3. Promote alternative + lock reading  
4. Session history + persist last reading  
5. VoiceOver + Dynamic Type  
6. Share card + haptics  

---

## Related

- [`README.md`](README.md) — active/finished table  
- [`../FutureIdeas/backlog.md`](../FutureIdeas/backlog.md) — longer-term ideas  
- [`../docs/agent-build-checklist.md`](../docs/agent-build-checklist.md) — phase tracking  
