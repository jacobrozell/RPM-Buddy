import Foundation

enum FirebaseBootstrap {
    private static let featureFlags = LocalFeatureFlagsProvider()

    /// Skip Firebase when the bundled plist is missing or still the checked-in placeholder.
    static var shouldConfigure: Bool {
        guard
            let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let plist = NSDictionary(contentsOfFile: path),
            let appID = plist["GOOGLE_APP_ID"] as? String
        else {
            return false
        }
        return !appID.contains("REPLACE_WITH")
    }

    static var isAnalyticsCollectionEnabled: Bool {
        analyticsCollectionEnabled(featureFlags: featureFlags)
    }

    static var isCrashlyticsCollectionEnabled: Bool {
        crashlyticsCollectionEnabled(featureFlags: featureFlags)
    }

    static func analyticsCollectionEnabled(featureFlags: FeatureFlagsProvider) -> Bool {
        shouldConfigure && featureFlags.isEnabled(.enableFirebaseAnalytics)
    }

    static func crashlyticsCollectionEnabled(featureFlags: FeatureFlagsProvider) -> Bool {
        shouldConfigure && featureFlags.isEnabled(.enableFirebaseCrashlytics)
    }
}
