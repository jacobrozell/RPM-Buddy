import Foundation
import Testing
@testable import RPMBuddy

@Test("Bootstrap maps to GA4 app_open")
func mapsBootstrapReadyToAppOpen() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .appLifecycle,
        eventName: "app_bootstrap_ready",
        message: "Ready.",
        metadata: [:]
    )

    let event = FirebaseAnalyticsEventMapping.map(entry, appVersion: "1.0")
    #expect(event?.name == "app_open")
    #expect(event?.parameters["app_version"] == "1.0")
    #expect(event?.parameters["log_category"] == "appLifecycle")
}

@Test("Tempo lock keeps buckets and drops raw audio fields")
func mapsTempoLockedWithoutRawReading() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .detector,
        eventName: "tempo_locked",
        message: "Locked.",
        metadata: [
            "bpmBucket": "120_129",
            "confidenceBucket": "high",
            "source": "mic",
            "bpm": "124",
            "samples": "secret"
        ]
    )

    let event = FirebaseAnalyticsEventMapping.map(entry, appVersion: nil)
    #expect(event?.name == "tempo_locked")
    #expect(event?.parameters["bpmBucket"] == "120_129")
    #expect(event?.parameters["confidenceBucket"] == "high")
    #expect(event?.parameters["source"] == "mic")
    #expect(event?.parameters["bpm"] == nil)
    #expect(event?.parameters["samples"] == nil)
}

@Test("Beat sync maps buckets and drops an exact BPM")
func mapsBeatSyncedWithoutExactBPM() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .detector,
        eventName: "beat_synced",
        message: "Synced.",
        metadata: [
            "bpmBucket": "80_89",
            "source": "tap",
            "status": "snapped",
            "bpm": "80"
        ]
    )

    let event = FirebaseAnalyticsEventMapping.map(entry, appVersion: nil)
    #expect(event?.name == "beat_synced")
    #expect(event?.parameters["bpmBucket"] == "80_89")
    #expect(event?.parameters["status"] == "snapped")
    #expect(event?.parameters["bpm"] == nil)
}

@Test("Unknown events stay out of GA4")
func dropsNonAllowlistedEvents() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .detector,
        eventName: "analysis_window",
        message: "Window.",
        metadata: ["bpmBucket": "90_99"]
    )

    #expect(FirebaseAnalyticsEventMapping.map(entry, appVersion: nil) == nil)
}

@Test("Capture failure is a Crashlytics non-fatal; permission warning is not")
func mapsListenFailedNonFatal() {
    let captureFailure = LogEntry(
        timestamp: Date(),
        level: .error,
        category: .detector,
        eventName: "listen_failed",
        message: "Capture failed.",
        metadata: ["errorCode": "capture_failed", "source": "mic", "path": "/tmp/mic"]
    )
    let permissionWarning = LogEntry(
        timestamp: Date(),
        level: .warning,
        category: .detector,
        eventName: "listen_failed",
        message: "Need mic.",
        metadata: ["errorCode": "permission_required"]
    )

    let error = FirebaseCrashlyticsEventMapping.nonFatalError(for: captureFailure, appVersion: "1.0")
    #expect(error?.domain == "com.jacobrozell.rpmbuddy.logger")
    #expect(error?.code == 2001)
    #expect(error?.userInfo["errorCode"] as? String == "capture_failed")
    #expect(error?.userInfo["path"] == nil)
    #expect(FirebaseCrashlyticsEventMapping.nonFatalError(for: permissionWarning, appVersion: nil) == nil)
}

@Test("BPM and duration buckets stay coarse")
func analyticsBuckets() {
    #expect(AnalyticsBuckets.bpmBucket(124) == "120_129")
    #expect(AnalyticsBuckets.bpmBucket(90) == "90_99")
    #expect(AnalyticsBuckets.confidenceBucket(0.2) == "low")
    #expect(AnalyticsBuckets.confidenceBucket(0.5) == "medium")
    #expect(AnalyticsBuckets.confidenceBucket(0.82) == "high")
    #expect(AnalyticsBuckets.durationBucket(seconds: 4) == "under_10s")
    #expect(AnalyticsBuckets.durationBucket(seconds: 45) == "30_120s")
}

@Suite("Firebase collection gates")
struct FirebaseBootstrapTests {
    @Test("Analytics follows the feature flag and a real plist")
    func analyticsCollectionRequiresFeatureFlag() {
        let enabled = StubFeatureFlags(flags: [.enableFirebaseAnalytics: true])
        let disabled = StubFeatureFlags(flags: [.enableFirebaseAnalytics: false])

        #expect(
            FirebaseBootstrap.analyticsCollectionEnabled(featureFlags: enabled)
                == FirebaseBootstrap.shouldConfigure
        )
        #expect(!FirebaseBootstrap.analyticsCollectionEnabled(featureFlags: disabled))
    }

    @Test("Debug launch arguments keep collection off")
    func launchArgumentsDisableCollection() {
        let debugOn = LocalFeatureFlagsProvider(arguments: ["-firebase_analytics_debug"])
        let explicitlyOff = LocalFeatureFlagsProvider(
            arguments: ["-firebase_analytics_debug", "-disable_firebase_analytics"]
        )
        let uiTest = LocalFeatureFlagsProvider(arguments: ["-ui_test_reset", "-firebase_analytics_debug"])

        #expect(debugOn.isEnabled(.enableFirebaseAnalytics))
        #expect(!explicitlyOff.isEnabled(.enableFirebaseAnalytics))
        #expect(!uiTest.isEnabled(.enableFirebaseCrashlytics))
        #expect(!LocalFeatureFlagsProvider(arguments: []).isEnabled(.enableFirebaseAnalytics))
    }
}

private struct StubFeatureFlags: FeatureFlagsProvider {
    let flags: [FeatureFlag: Bool]

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        flags[flag] ?? false
    }
}
