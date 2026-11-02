import Foundation

protocol RedactionPolicy: Sendable {
    func redact(metadata: [String: String]) -> [String: String]
}

struct DefaultRedactionPolicy: RedactionPolicy {
    private let allowedMetadataKeys: Set<String>
    private let sensitiveKeyFragments: [String]

    init(
        allowedMetadataKeys: Set<String> = AnalyticsMetadataKeys.defaultRedactionAllowed,
        sensitiveKeyFragments: [String] = ["token", "secret", "password", "credential"]
    ) {
        self.allowedMetadataKeys = allowedMetadataKeys
        self.sensitiveKeyFragments = sensitiveKeyFragments
    }

    func redact(metadata: [String: String]) -> [String: String] {
        metadata.reduce(into: [:]) { partialResult, pair in
            guard !AnalyticsMetadataKeys.isBlockedPersonalDataKey(pair.key) else { return }
            guard allowedMetadataKeys.contains(pair.key) else { return }
            let lowercasedKey = pair.key.lowercased()
            if sensitiveKeyFragments.contains(where: { lowercasedKey.contains($0) }) {
                partialResult[pair.key] = "[REDACTED]"
            } else {
                partialResult[pair.key] = pair.value
            }
        }
    }
}
