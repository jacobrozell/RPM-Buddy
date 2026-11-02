# Brainstorm — RPM Buddy

**Non-authoritative** notes from the initial idea. See `specs/` for behavior contracts.

## Idea

Simple microphone app: hold the phone up to a record or speaker, analyze ambient audio, estimate BPM, and show a confidence meter so users know how reliable the reading is.

## Personas

- **DJ / producer** — quick sanity check on a track's tempo
- **Vinyl listener** — curious about BPM while flipping records
- **Student musician** — learning to hear tempo without a metronome app

## v1 scope (shipped intent)

- Single-screen detector with Listen / Stop
- Live mic capture + rolling analysis window
- Large BPM display + confidence gauge + input level
- Mic permission onboarding
- Settings with support / privacy / accessibility links
- No history, no tap-tempo, no Apple Music integration

## Deferred

- Session history and export
- Tap tempo fallback
- Watch complication / widget
- Multi-locale strings beyond English

## Agent defaults chosen (2026-06-21)

| Decision | Choice |
|----------|--------|
| App name | RPM Buddy |
| Bundle ID | com.jacobrozell.rpmbuddy |
| Min iOS | 18.0 |
| Telemetry | Off |
| Orientation | Portrait only |
| Tip link | None |
