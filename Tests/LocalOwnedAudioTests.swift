import Foundation
import Testing
@testable import RPMBuddy

/// Manual/dev-only: analyze personally owned files on disk when the album folder is present.
/// CI skips silently. Never bundle these tracks in the app.
@Suite("Local owned audio (manual only)")
struct LocalOwnedAudioTests {
    @Test("Analyze local album directory when RPMBUDDY_LOCAL_AUDIO_DIR is set")
    func analyzeLocalAlbumIfConfigured() {
        let directory = LocalAlbumLocator.directory(named: FacesAlbumCatalog.albumName)
            ?? ProcessInfo.processInfo.environment["RPMBUDDY_LOCAL_AUDIO_DIR"].map {
                URL(fileURLWithPath: $0, isDirectory: true)
            }
        guard let directory, FileManager.default.fileExists(atPath: directory.path) else {
            return
        }

        let results = AlbumAnalysisSupport.analyze(
            directory: directory,
            references: FacesAlbumCatalog.verificationTracks
        )
        guard !results.isEmpty else {
            Issue.record("No audio files in \(directory.path)")
            return
        }

        AlbumAnalysisSupport.printReport(title: "RPMBuddy local album analysis", results: results)

        let detected = results.filter { $0.detectedBPM != nil }
        #expect(!detected.isEmpty, "Expected at least one track with a detectable tempo")
    }
}
