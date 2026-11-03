import Foundation

struct ScanRecord: Codable, Equatable, Identifiable, Sendable {
    static let storedLimit = 8

    let id: UUID
    let bpm: Int
    let confidence: Double
    let loggedAt: Date
}

protocol ScanHistoryStore: AnyObject {
    func load() -> [ScanRecord]
    func save(_ scans: [ScanRecord])
}

final class MemoryScanHistoryStore: ScanHistoryStore {
    private var scans: [ScanRecord]

    init(_ scans: [ScanRecord] = []) {
        self.scans = scans
    }

    func load() -> [ScanRecord] { scans }

    func save(_ scans: [ScanRecord]) {
        self.scans = scans
    }
}

final class FileScanHistoryStore: ScanHistoryStore {
    private let fileURL: URL

    init(fileURL: URL = FileScanHistoryStore.defaultFileURL()) {
        self.fileURL = fileURL
    }

    func load() -> [ScanRecord] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([ScanRecord].self, from: data)) ?? []
    }

    func save(_ scans: [ScanRecord]) {
        let directory = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(scans) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("RPMBuddy", isDirectory: true)
            .appendingPathComponent("scans.json")
    }
}
