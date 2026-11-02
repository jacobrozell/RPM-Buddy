# Logging, Firebase Analytics, and GA4

## Policy

- Feature code calls `AppLogging.logger`. It never imports Firebase.
- Audio samples, file paths, and exact continuous BPM readings are not logged.
- `tempo_locked` fires once per listen session. BPM is a 10-wide bucket (`120_129`), confidence is `low` / `medium` / `high`.
- Debug, CI, and UI tests (`-ui_test_reset`, `-disable_firebase_analytics`) do not collect.
- Release collects only when `GoogleService-Info.plist` is real (no `REPLACE_WITH`). `-firebase_analytics_debug` turns collection on in Debug.

## Pipeline

```
Feature → AppLogging.logger → DefaultAppLogger
  → ConsoleLogSink (OSLog)
  → FirebaseAnalyticsLogSink (.info+ allowlist → GA4)
  → FirebaseCrashlyticsLogSink (.info+ breadcrumbs, .error+ non-fatals)
```

`app_bootstrap_ready` is sent to GA4 as `app_open`.

## Allowlist

| Event | When |
|-------|------|
| `app_open` | Launch |
| `mic_permission_result` | Permission changes to granted or denied |
| `listen_started` / `listen_stopped` | Mic or UI-test mock session |
| `listen_failed` | Capture throws (`errorCode=capture_failed`) or listen tapped without mic permission |
| `listen_quiet` | Once per session when the signal stays quiet |
| `tempo_locked` | First stable reading in the session |
| `beat_synced` | Taps or Too slow / Too fast lock a count. `status` is `snapped`, `tap_only`, or `octave`. BPM stays bucketed. |
| `settings_opened` | Settings sheet |
| `metronome_self_test_completed` | Settings verification finishes |

Crashlytics non-fatal: `listen_failed` at `.error` only, code `2001`. Permission failures are `.warning` and stay out of non-fatals.

## Ship setup

1. Firebase console → add iOS app `com.jacobrozell.rpmbuddy` (this creates the GA4 property).
2. `cp Resources/GoogleService-Info.plist.example Resources/GoogleService-Info.plist` and replace placeholders. The real file is gitignored.
3. Hosted privacy page must say product analytics is collected before TestFlight. Audio still stays on device.

## Verification

| Field | Value |
|-------|-------|
| Target release | 1.0 |
| Last verified | 2026-11-02 |
| Primary paths | `Sources/Support/Logging/`, `Sources/Support/Bootstrap/FirebaseBootstrap.swift` |
