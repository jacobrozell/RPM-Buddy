import Foundation

enum AnalyticsMetadataKeys {
    static let firebaseParameters: Set<String> = [
        "status",
        "source",
        "errorCode",
        "bpmBucket",
        "confidenceBucket",
        "durationBucket",
        "hadReading",
        "passedCount",
        "failedCount"
    ]

    static let crashlyticsParameters: Set<String> = [
        "status",
        "source",
        "errorCode"
    ]

    static let defaultRedactionAllowed: Set<String> = firebaseParameters

    private static let blockedFragments = [
        "email",
        "phone",
        "name",
        "address",
        "token",
        "secret",
        "password",
        "audio",
        "sample",
        "path",
        "message"
    ]

    static func isBlockedPersonalDataKey(_ key: String) -> Bool {
        let lowercased = key.lowercased()
        return blockedFragments.contains { lowercased.contains($0) }
    }
}
