import Foundation
import Testing
@testable import RPMBuddy

@Suite("Metronome fixtures", .serialized)
struct MetronomeFixtureTests {
    @Test("Bundled manifest fixtures analyze near labeled BPM", arguments: MetronomeFixtureCatalog.generated)
    func analyzesFixture(fixture: MetronomeFixture) {
        guard let url = fixture.url(in: Bundle.main) else {
            Issue.record("Missing bundled fixture: \(fixture.filename)")
            return
        }
        let result = FileBPMEstimator.estimate(url: url)
        #expect(result.bpm != nil, "Expected BPM for \(fixture.filename)")
        if let bpm = result.bpm {
            #expect(
                abs(bpm - fixture.expectedBPM) <= fixture.toleranceBPM,
                "Expected ~\(fixture.expectedBPM) for \(fixture.filename), got \(bpm)"
            )
        }
        #expect(result.confidence > 0.15, "Expected usable confidence for \(fixture.filename)")
    }

    @Test("Metronome self-test runner marks 120 BPM fixture as pass")
    func selfTestRunner() {
        let result = MetronomeSelfTest.run(fixture: MetronomeFixtureCatalog.primaryVerification)
        #expect(result.passed)
        #expect(result.estimate.bpm != nil)
    }
}
