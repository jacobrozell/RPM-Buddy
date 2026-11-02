import Foundation

struct FirebaseAnalyticsEvent: Equatable, Sendable {
    let name: String
    let parameters: [String: String]
}

enum FirebaseAnalyticsEventMapping {
    private static let allowlistedLogEvents: Set<String> = [
        "app_bootstrap_ready",
        "mic_permission_result",
        "listen_started",
        "listen_stopped",
        "listen_failed",
        "listen_quiet",
        "tempo_locked",
        "settings_opened",
        "metronome_self_test_completed"
    ]

    private static let firebaseNameOverrides: [String: String] = [
        "app_bootstrap_ready": "app_open"
    ]

    static func map(_ entry: LogEntry, appVersion: String?) -> FirebaseAnalyticsEvent? {
        guard allowlistedLogEvents.contains(entry.eventName) else { return nil }

        var parameters = FirebaseMetadataSanitizer.sanitize(
            entry.metadata,
            allowedKeys: AnalyticsMetadataKeys.firebaseParameters
        )
        if let appVersion, !appVersion.isEmpty {
            parameters["app_version"] = appVersion
        }
        parameters["log_category"] = entry.category.rawValue
        let firebaseName = firebaseNameOverrides[entry.eventName] ?? entry.eventName
        return FirebaseAnalyticsEvent(name: firebaseName, parameters: parameters)
    }
}
