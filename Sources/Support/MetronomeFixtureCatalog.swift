import Foundation

struct MetronomeFixture: Identifiable, Sendable, Equatable {
    let id: String
    let filename: String
    let expectedBPM: Int
    let toleranceBPM: Int
    let license: String

    var displayName: String { "\(expectedBPM) BPM metronome" }

    init(id: String, filename: String, expectedBPM: Int, toleranceBPM: Int = 6, license: String) {
        self.id = id
        self.filename = filename
        self.expectedBPM = expectedBPM
        self.toleranceBPM = toleranceBPM
        self.license = license
    }

    func url(in bundle: Bundle = .main) -> URL? {
        if let nested = bundle.url(
            forResource: id,
            withExtension: "wav",
            subdirectory: "Fixtures"
        ) {
            return nested
        }
        return bundle.url(forResource: id, withExtension: "wav")
    }
}

enum MetronomeFixtureCatalog {
    private static let generatedBPMs = [50, 60, 80, 90, 100, 120, 128, 140, 145, 160]

    static let generated: [MetronomeFixture] =
        generatedBPMs.map { bpm in
            MetronomeFixture(
                id: "metronome-\(bpm)bpm-30s",
                filename: "metronome-\(bpm)bpm-30s.wav",
                expectedBPM: bpm,
                license: "Project-generated (CC0-equivalent)"
            )
        } + [
            MetronomeFixture(
                id: "metronome-bigsoundbank-120bpm-12s",
                filename: "metronome-bigsoundbank-120bpm-12s.wav",
                expectedBPM: 120,
                toleranceBPM: 10,
                license: "CC0 — BigSoundBank #0468"
            ),
        ]

    static let primaryVerification = MetronomeFixture(
        id: "metronome-120bpm-30s",
        filename: "metronome-120bpm-30s.wav",
        expectedBPM: 120,
        license: "Project-generated (CC0-equivalent)"
    )
}

struct MetronomeSelfTestResult: Equatable, Sendable {
    let fixture: MetronomeFixture
    let estimate: BPMEstimate
    let passed: Bool

    var summary: String {
        let detected = estimate.bpm.map(String.init) ?? "—"
        let confidence = Int((estimate.confidence * 100).rounded())
        let status = passed ? "Pass" : "Check"
        return "\(status): detected \(detected) BPM (expected \(fixture.expectedBPM)), confidence \(confidence)%"
    }
}

enum MetronomeSelfTest {
    static func run(fixture: MetronomeFixture) -> MetronomeSelfTestResult {
        guard let url = fixture.url() else {
            return MetronomeSelfTestResult(fixture: fixture, estimate: .silent, passed: false)
        }
        let estimate = FileBPMEstimator.estimate(url: url)
        let passed = estimate.bpm.map { abs($0 - fixture.expectedBPM) <= fixture.toleranceBPM } ?? false
        return MetronomeSelfTestResult(fixture: fixture, estimate: estimate, passed: passed)
    }
}
