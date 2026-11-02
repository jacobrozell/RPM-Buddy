import Foundation
@testable import RPMBuddy

enum FacesAlbumCatalog {
    static let albumName = "Mac Miller - Faces"

    /// Reference tempos from public BPM databases; analyzer may fold half/double time.
    static let verificationTracks: [AlbumReferenceTrack] = [
        AlbumReferenceTrack(filenameContains: "Insomniak", expectedBPM: 120),
        AlbumReferenceTrack(filenameContains: "Diablo", expectedBPM: 80),
        AlbumReferenceTrack(filenameContains: "New Faces", expectedBPM: 111, toleranceBPM: 16),
        AlbumReferenceTrack(filenameContains: "Malibu", expectedBPM: 78),
        AlbumReferenceTrack(filenameContains: "Friends", expectedBPM: 148),
        AlbumReferenceTrack(filenameContains: "What Do You Do", expectedBPM: 88),
        AlbumReferenceTrack(filenameContains: "Therapy", expectedBPM: 140),
        AlbumReferenceTrack(filenameContains: "Polo Jeans", expectedBPM: 147),
        AlbumReferenceTrack(filenameContains: "Ave Maria", expectedBPM: 171),
        AlbumReferenceTrack(filenameContains: "Uber", expectedBPM: 170),
        AlbumReferenceTrack(filenameContains: "Rain", expectedBPM: 177),
    ]
}

struct AlbumTrackAnalysis: Sendable, Equatable {
    let label: String
    let filename: String
    let estimate: BPMEstimate
    let expectedBPM: Int?
    let toleranceBPM: Int

    init(
        label: String = "Album",
        filename: String,
        estimate: BPMEstimate,
        expectedBPM: Int?,
        toleranceBPM: Int
    ) {
        self.label = label
        self.filename = filename
        self.estimate = estimate
        self.expectedBPM = expectedBPM
        self.toleranceBPM = toleranceBPM
    }

    var detectedBPM: Int? { estimate.bpm }

    var matchesReference: Bool {
        guard let detectedBPM, let expectedBPM else { return false }
        return TempoMatch.isEquivalent(
            detected: detectedBPM,
            expected: expectedBPM,
            tolerance: toleranceBPM
        )
    }

    var honestlyUncertain: Bool {
        estimate.bpm == nil || estimate.confidence < 0.15
    }

    var passesVerification: Bool {
        matchesReference || honestlyUncertain
    }

    var summaryLine: String {
        let bpm = detectedBPM.map(String.init) ?? "—"
        let confidence = Int((estimate.confidence * 100).rounded())
        if let expectedBPM {
            let status = passesVerification ? "pass" : "fail"
            return "\(label) \(filename): \(bpm) BPM, confidence \(confidence)% (expected ~\(expectedBPM), \(status))"
        }
        return "\(label) \(filename): \(bpm) BPM, confidence \(confidence)%"
    }
}

enum TempoMatch {
    /// True when `detected` matches `expected` directly or at a folded octave (half/double time).
    static func isEquivalent(detected: Int, expected: Int, tolerance: Int) -> Bool {
        var candidate = Double(expected)
        for _ in 0..<5 {
            if candidate >= 70, candidate <= 180 {
                if abs(detected - Int(candidate.rounded())) <= tolerance {
                    return true
                }
            }
            candidate /= 2
        }

        candidate = Double(expected)
        for _ in 0..<5 {
            candidate *= 2
            if candidate > 180 { break }
            if abs(detected - Int(candidate.rounded())) <= tolerance {
                return true
            }
        }
        return false
    }
}

enum AlbumAnalysisSupport {
    static func analyze(
        directory: URL,
        references: [AlbumReferenceTrack],
        label: String = "Album"
    ) -> [AlbumTrackAnalysis] {
        LocalAlbumLocator.audioFiles(in: directory).map { url in
            let reference = references.first {
                url.lastPathComponent.localizedCaseInsensitiveContains($0.filenameContains)
            }
            return AlbumTrackAnalysis(
                label: label,
                filename: url.lastPathComponent,
                estimate: FileBPMEstimator.estimate(url: url),
                expectedBPM: reference?.expectedBPM,
                toleranceBPM: reference?.toleranceBPM ?? 8
            )
        }
    }

    static func printReport(title: String, results: [AlbumTrackAnalysis]) {
        print("━━ \(title) ━━")
        for result in results {
            print(result.summaryLine)
        }
        let verified = results.filter { $0.expectedBPM != nil }
        let passing = verified.filter { $0.passesVerification }
        let detected = results.filter { $0.detectedBPM != nil }
        print("Summary: \(detected.count)/\(results.count) tracks detected, \(passing.count)/\(verified.count) reference tracks pass")
        print("━━ end ━━")
    }
}
