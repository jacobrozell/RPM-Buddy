import Foundation

enum FirebaseCrashlyticsEventMapping {
    private static let errorDomain = "com.jacobrozell.rpmbuddy.logger"

    static let eventCodes: [String: Int] = [
        "listen_failed": 2001
    ]

    static func nonFatalError(for entry: LogEntry, appVersion: String?) -> NSError? {
        guard entry.level >= .error,
              let code = eventCodes[entry.eventName]
        else {
            return nil
        }

        var userInfo = FirebaseMetadataSanitizer.sanitize(
            entry.metadata,
            allowedKeys: AnalyticsMetadataKeys.crashlyticsParameters
        )
        userInfo["log_category"] = entry.category.rawValue
        userInfo["event_name"] = entry.eventName
        if let appVersion, !appVersion.isEmpty {
            userInfo["app_version"] = appVersion
        }
        return NSError(domain: errorDomain, code: code, userInfo: userInfo)
    }
}
