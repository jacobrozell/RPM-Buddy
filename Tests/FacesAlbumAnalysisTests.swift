import Foundation
import Testing
@testable import RPMBuddy

/// Dev-only regression tests for Mac Miller — Faces on disk.
/// Skips silently in CI when the gitignored album folder is absent.
@Suite("Faces album analysis (local only)", .serialized)
struct FacesAlbumAnalysisTests {
    private func facesDirectory() -> URL? {
        LocalAlbumLocator.directory(named: FacesAlbumCatalog.albumName)
    }

    @Test("Verification tracks match reference BPM or report low confidence")
    func verificationTracks() {
        guard let directory = facesDirectory() else { return }

        let results = AlbumAnalysisSupport.analyze(
            directory: directory,
            references: FacesAlbumCatalog.verificationTracks,
            label: "Faces"
        )
        let verified = results.filter { $0.expectedBPM != nil }
        guard !verified.isEmpty else {
            Issue.record("No Faces verification tracks found in \(directory.path)")
            return
        }

        AlbumAnalysisSupport.printReport(title: "Faces verification tracks", results: verified)

        for result in verified where !result.passesVerification {
            print("⚠️ \(result.summaryLine)")
        }

        let passingCount = verified.filter { $0.passesVerification }.count
        #expect(
            passingCount == verified.count,
            "Expected all reference tracks to pass; got \(passingCount)/\(verified.count)"
        )
    }

    @Test("Insomniak estimates near 120 BPM with usable confidence")
    func insomniakNear120() {
        guard let directory = facesDirectory(),
              let url = LocalAlbumLocator.firstAudioFile(in: directory, matching: "Insomniak") else {
            return
        }

        let result = FileBPMEstimator.estimate(url: url)
        print(
            "Faces Insomniak: \(result.bpm.map(String.init) ?? "—") BPM, " +
                "confidence \(Int((result.confidence * 100).rounded()))%"
        )

        guard let bpm = result.bpm else {
            Issue.record("Insomniak did not produce a BPM estimate")
            return
        }

        #expect(result.confidence >= 0.12)
        #expect(TempoMatch.isEquivalent(detected: bpm, expected: 120, tolerance: 8))
    }

    @Test("Diablo estimates near 80 BPM or reports low confidence")
    func diabloNear80() {
        guard let directory = facesDirectory(),
              let url = LocalAlbumLocator.firstAudioFile(in: directory, matching: "Diablo") else {
            return
        }

        let result = FileBPMEstimator.estimate(url: url)
        print(
            "Faces Diablo: \(result.bpm.map(String.init) ?? "—") BPM, " +
                "confidence \(Int((result.confidence * 100).rounded()))%"
        )

        if let bpm = result.bpm {
            #expect(TempoMatch.isEquivalent(detected: bpm, expected: 80, tolerance: 8))
        } else {
            #expect(result.confidence < 0.15)
        }
    }

    @Test("Full album analysis report")
    func fullAlbumReport() {
        guard let directory = facesDirectory() else { return }

        let results = AlbumAnalysisSupport.analyze(
            directory: directory,
            references: FacesAlbumCatalog.verificationTracks,
            label: "Faces"
        )
        guard !results.isEmpty else {
            Issue.record("No audio files in \(directory.path)")
            return
        }

        AlbumAnalysisSupport.printReport(title: "Faces full album", results: results)

        let detected = results.filter { $0.detectedBPM != nil }
        #expect(!detected.isEmpty, "Expected at least one Faces track with a detectable tempo")
    }
}
