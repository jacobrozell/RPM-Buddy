import Foundation
import Testing
@testable import RPMBuddy

@Suite("I Love Life Thank You album analysis (local only)", .serialized)
struct ILTYAlbumAnalysisTests {
    private func albumDirectory() -> URL? {
        LocalAlbumLocator.directory(named: ILTYAlbumCatalog.albumName)
    }

    @Test("Full album analysis report")
    func fullAlbumReport() {
        guard let directory = albumDirectory() else { return }

        let results = AlbumAnalysisSupport.analyze(
            directory: directory,
            references: ILTYAlbumCatalog.verificationTracks,
            label: "ILLTY"
        )
        guard !results.isEmpty else {
            Issue.record("No audio files in \(directory.path)")
            return
        }

        AlbumAnalysisSupport.printReport(title: "ILLTY full album", results: results)

        let detected = results.filter { $0.detectedBPM != nil }
        #expect(!detected.isEmpty, "Expected at least one ILLTY track with a detectable tempo")
    }

    @Test("Verification tracks match reference BPM or report low confidence")
    func verificationTracks() {
        guard let directory = albumDirectory() else { return }

        let results = AlbumAnalysisSupport.analyze(
            directory: directory,
            references: ILTYAlbumCatalog.verificationTracks,
            label: "ILLTY"
        )
        let verified = results.filter { $0.expectedBPM != nil }
        guard !verified.isEmpty else {
            Issue.record("No ILLTY verification tracks configured")
            return
        }

        AlbumAnalysisSupport.printReport(title: "ILLTY verification tracks", results: verified)

        for result in verified where !result.passesVerification {
            print("⚠️ \(result.summaryLine)")
        }

        let passingCount = verified.filter { $0.passesVerification }.count
        #expect(
            passingCount == verified.count,
            "Expected all reference tracks to pass; got \(passingCount)/\(verified.count)"
        )
    }

    @Test("Title track estimates near 93 BPM with usable confidence")
    func titleTrackNear93() {
        guard let directory = albumDirectory(),
              let url = LocalAlbumLocator.firstAudioFile(
                in: directory,
                matching: "I Love Life Thank You"
              ) else {
            return
        }

        let result = FileBPMEstimator.estimate(url: url)
        print(
            "ILLTY title: \(result.bpm.map(String.init) ?? "—") BPM, " +
                "confidence \(Int((result.confidence * 100).rounded()))%"
        )

        guard let bpm = result.bpm else {
            Issue.record("Title track did not produce a BPM estimate")
            return
        }

        #expect(result.confidence >= 0.12)
        #expect(TempoMatch.isEquivalent(detected: bpm, expected: 93, tolerance: 8))
    }
}
