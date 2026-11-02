# Test audio sources — BPM-labeled, free

**Last updated:** 2026-06-21

Curated sources for RPM Buddy manual QA, device testing, and optional bundled fixtures. **Do not commit large downloads to git** — add selected clips under `Resources/Fixtures/` (gitignored or small WAV only) with a `README` citing license + expected BPM.

---

## Quick picks (small files, explicit BPM)

Best for first device pass and optional unit/integration fixtures.

| Expected BPM | Source | Format | License | Link |
|-------------|--------|--------|---------|------|
| **120** | BigSoundBank — Mechanical metronome | WAV ~1.2 MB | **CC0** (public domain) | [bigsoundbank.com/metronome-a-120bpm-s0468.html](https://bigsoundbank.com/metronome-a-120bpm-s0468.html) |
| **120** | BigSoundBank — Electric metronome | WAV ~6 s | CC0 | [Search “metronome”](https://bigsoundbank.com/search?q=metronome) |
| **120** | Freesound — Metronome 120 bpm (Sadiquecat) | WAV ~4 s | CC0 (attribution appreciated) | [freesound.org/people/Sadiquecat/sounds/793343](https://freesound.org/people/Sadiquecat/sounds/793343/) |
| **120** | LiQWYD — *Breeze* | MP3 + WAV | CC BY 3.0 (credit artist) | [free-stock-music.com/liqwyd-breeze.html](https://www.free-stock-music.com/liqwyd-breeze.html) |
| **120** | Snabisch — *The Most Beautiful 120 BPM* | WAV ~23 MB | CC BY 3.0 | [opengameart.org/content/the-most-beautiful-120-bpm](https://opengameart.org/content/the-most-beautiful-120-bpm) |
| **120** | Mega Music Monkey — *Happy* Song | MP3 | CC 3.0 (credit MusicCatRF.com) | [megamusicmonkey.com/.../120-bpm-creative-commons](https://megamusicmonkey.com/free-music-happy-song-120-bpm-creative-commons/) |
| **90** | Deoxys Beats — *Friend A* | MP3 + WAV | CC BY-SA 3.0 | [free-stock-music.com/deoxys-beats-friend-a.html](https://www.free-stock-music.com/deoxys-beats-friend-a.html) |
| **128** | FSM Team — *Urban Commuters* | MP3 + WAV | CC BY 4.0 | [free-stock-music.com/fsm-team-escp-urban-commuters.html](https://www.free-stock-music.com/fsm-team-escp-urban-commuters.html) |

**Half-time / double-time check:** At **120** primary, RPM Buddy should offer **60** and **240** alternatives. Play the 120 BPM metronome and confirm primary ≈120 (not 60).

---

## Spencer Tweedy — Drumprints Vol. 1 (CC BY 4.0)

Real drum loops; **tempo is in the track title** (per [Bandcamp notes](https://spencertweedy.bandcamp.com/album/drumprints-vol-1-2301)). Free / pay-what-you-want; ~280 MB zip.

| Track | Labeled BPM | URL |
|-------|-------------|-----|
| DP2301 Contact Sheet 128 | **128** | [bandcamp track](https://spencertweedy.bandcamp.com/track/dp2301-contact-sheet-128) |
| DP2301 Contact Sheet 101 A / B | **101** | [101 A](https://spencertweedy.bandcamp.com/track/dp2301-contact-sheet-101-a) · [101 B](https://spencertweedy.bandcamp.com/track/dp2301-contact-sheet-101-b) |
| DP2301 Longform 101 | **101** | [track](https://spencertweedy.bandcamp.com/track/dp2301-longform-101) |
| DP2301 Contact Sheet 158 | **158** | [track](https://spencertweedy.bandcamp.com/track/dp2301-contact-sheet-158) |
| DP2301 Longform 158 | **158** | [track](https://spencertweedy.bandcamp.com/track/dp2301-longform-158) |
| DP2301 Contact Sheet 167 | **167** | [track](https://spencertweedy.bandcamp.com/track/dp2301-contact-sheet-167) |

Download: [spencertweedy.com/drumprints](https://spencertweedy.com/drumprints) · Credit: *“Drum samples by Spencer Tweedy’s Drumprints.”*

Good for **full-band feel** (not just clicks) — closer to “hold phone at speaker” testing.

---

## Owned music (local only)

For albums you own (e.g. **Mac Miller — Faces** at repo root or under `local-test-media/albums/`):

- **Gitignored** — never in the app bundle or git history
- **Pre-commit hook** blocks staged MP3/M4A/FLAC
- Batch analyze on disk (same estimator as Settings verification):

```bash
bash Scripts/analyze-local-album.sh "Mac Miller - Faces"
```

See [`local-test-media/README.md`](../local-test-media/README.md).

---

| Tool | BPM range | Output | License |
|------|-----------|--------|---------|
| [BigSoundBank Metronome Generator](https://bigsoundbank.com/generator/metronome.html) | 30–240+ | WAV export | Free generator |
| [ImageOnline Metronome Generator](https://imageonline.co/metronome-generator.php) | 30–300 | WAV / MP3 | Free; client-side |

Use to build a **regression matrix**: 70, 90, 120, 128, 158 BPM × 30–60 s loops.

---

## Large ML datasets (BPM in filename / metadata)

For bulk calibration or ML-style eval — **multi-GB**; BPM embedded in filenames (WaivOps / Patchbanks, **CC BY 4.0**).

| Dataset | BPM range | Size | Link |
|---------|-----------|------|------|
| **EDM-TR9** | 120–140 | ~4.8 GB | [Zenodo](https://zenodo.org/records/10278066) · [GitHub](https://github.com/patchbanks/WaivOps-EDM-TR9) |
| **HH-LFBB** (lofi hip-hop) | 60–96 | ~15 GB | [Zenodo record 7523435](https://zenodo.org/record/7523435) · [GitHub](https://github.com/patchbanks/WaivOps-HH-LFBB) |
| **EDM-TECH** | 128–150 | ~12 GB WAV + JSON | [Zenodo 17584890](https://zenodo.org/records/17584890) |
| **HH-TRP** (trap) | 110–180 | ~22 GB | [Zenodo 15734094](https://zenodo.org/records/15734094) |

Filename pattern includes `bpm###` — ideal for scripted accuracy reports.

---

## Suggested RPM Buddy test matrix

| Scenario | Source | Pass criteria |
|----------|--------|---------------|
| Sanity / CI fixture | BigSoundBank 120 BPM metronome WAV | Primary 114–126; alternatives include 60 + 240 |
| Slow feel | Deoxys *Friend A* (90) or HH-LFBB clip | Primary ~86–94; half-time 45 if shown |
| Fast electronic | FSM *Urban Commuters* (128) or Drumprints 128 | Primary ~122–134 |
| Live drums | Spencer Tweedy 101 or 158 | Primary within ±6; confidence > 0.3 on device |
| Half-time trap | Play 120 clip; user promotes **60** | UI reflects promoted BPM |
| Weak signal | Same clip at low volume | Low confidence; no false BPM |

---

## Repo integration (optional next step)

1. Create `Resources/Fixtures/README.md` listing 2–3 committed clips (metronome 120 + one song).  
2. Add `Scripts/download-test-fixtures.sh` (curl) — **not** run in CI by default.  
3. Device test checklist row in `docs/release/` linking here.  
4. Never bundle WaivOps archives in git.

---

## License reminders

- **CC0** — no attribution required (Freesound/BigSoundBank metronomes).  
- **CC BY / BY-SA** — credit artist in fixture README and App Store credits if shipped in-app.  
- **NC tracks** — avoid for app that may ship commercially; free-stock-music.com labels NC per track.  
- WaivOps / Drumprints — CC BY 4.0; keep attribution in docs if used in marketing or bundled samples.
