import Foundation
import Testing
@testable import RPMBuddy

@Suite("Scan history")
struct ScanHistoryStoreTests {
    @Test("A scan file round-trips and keeps the newest eight")
    func roundTrip() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("rpmbuddy-scans-\(UUID().uuidString).json")
        let store = FileScanHistoryStore(fileURL: url)
        let newest = ScanRecord(
            id: UUID(),
            bpm: 145,
            confidence: 0.4,
            loggedAt: Date(timeIntervalSince1970: 20_000)
        )
        var scans = (0..<10).map { index in
            ScanRecord(
                id: UUID(),
                bpm: 80 + index,
                confidence: 0.2,
                loggedAt: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }
        scans.insert(newest, at: 0)
        scans = Array(scans.prefix(ScanRecord.storedLimit))
        store.save(scans)

        let loaded = store.load()
        #expect(loaded.count == ScanRecord.storedLimit)
        #expect(loaded.first == newest)
        try? FileManager.default.removeItem(at: url)
    }
}
