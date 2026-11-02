# Agent Build Checklist — RPM Buddy

Living status against the [generic template](../../../workspace/agent-build-checklist-template.md).

**App idea:** Hold your phone up to a record or speaker; RPM Buddy listens through the microphone, estimates BPM, and shows analysis confidence transparently.

Legend: ✅ done · 🟡 partial · ⛔ not started

| Phase | Title | Status | Notes |
|-------|-------|--------|-------|
| 0 | Repo & agent infra | ✅ | XcodeGen, SwiftLint, CI, git hooks, MCP template |
| 1 | Spec system | 🟡 | Core specs + inventory; drift script ⛔ |
| 2 | Design system & a11y | 🟡 | Confidence + level meters; full WCAG audit ⛔ |
| 3 | Domain (test-first) | ✅ | `BPMAnalyzer` + unit tests |
| 4 | Persistence | ⚪ | N/A for v1 |
| 5 | App shell | ✅ | Onboarding, root, settings |
| 6 | First vertical slice | ✅ | Listen → analyze → BPM + confidence |
| 7–13, 15–16 | Polish / ship | ⛔ | App Store assets, legal pages, device QA |
| 14 | Telemetry | 🟡 | Allowlisted GA4 + Crashlytics + logging. Deep links and widgets still out |

## Progress log

| Date | Change | Notes |
|------|--------|-------|
| 2026-06-21 | Initial repo bootstrap | Detector MVP, tests, CI |
| 2026-11-02 | Phase 14 telemetry | Firebase Analytics → GA4, Crashlytics breadcrumbs, OSLog facade |
