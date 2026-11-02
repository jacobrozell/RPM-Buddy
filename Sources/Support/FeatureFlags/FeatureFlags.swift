import Foundation

enum FeatureFlag: String, Sendable {
    case enableFirebaseAnalytics
    case enableFirebaseCrashlytics
}

protocol FeatureFlagsProvider: Sendable {
    func isEnabled(_ flag: FeatureFlag) -> Bool
}

struct LocalFeatureFlagsProvider: FeatureFlagsProvider {
    private let overrides: [FeatureFlag: Bool]
    private let arguments: [String]

    init(
        overrides: [FeatureFlag: Bool] = [:],
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        self.overrides = overrides
        self.arguments = arguments
    }

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        if let override = overrides[flag] {
            return override
        }
        return Self.defaultValue(for: flag, arguments: arguments)
    }

    static func defaultValue(for flag: FeatureFlag, arguments: [String]) -> Bool {
        switch flag {
        case .enableFirebaseAnalytics, .enableFirebaseCrashlytics:
            if arguments.contains("-disable_firebase_analytics") || arguments.contains("-ui_test_reset") {
                return false
            }
            if arguments.contains("-firebase_analytics_debug") {
                return true
            }
            #if DEBUG
            return false
            #else
            return true
            #endif
        }
    }
}
