import Foundation
import Testing
@testable import RPMBuddy

@Suite("Tempo interpretations")
struct TempoInterpretationsTests {
    @Test("120 BPM includes half-time, primary, and double-time")
    func alternativesFor120() {
        let alternatives = TempoInterpretations.alternatives(for: 120)
        let bpms = alternatives.map(\.bpm)
        #expect(bpms.contains(60))
        #expect(bpms.contains(120))
        #expect(bpms.contains(240))
        #expect(alternatives.first(where: \.isPrimary)?.bpm == 120)
    }

    @Test("90 BPM includes half-time and double-time in display range")
    func alternativesFor90() {
        let alternatives = TempoInterpretations.alternatives(for: 90)
        let bpms = alternatives.map(\.bpm)
        #expect(bpms.contains(45))
        #expect(bpms.contains(90))
        #expect(bpms.contains(180))
    }

    @Test("Reading bundles alternatives and timestamp")
    func tempoReadingMake() {
        let date = Date(timeIntervalSince1970: 1_000)
        let reading = TempoReading.make(primaryBPM: 128, confidence: 0.7, loggedAt: date)
        #expect(reading.primaryBPM == 128)
        #expect(reading.loggedAt == date)
        #expect(reading.alternatives.contains(where: { $0.bpm == 64 && $0.feel == .halfTime }))
    }

    @Test("Timestamp formatter returns non-empty text")
    func timestampFormatter() {
        let text = ReadingTimestampFormatter.string(for: Date())
        #expect(!text.isEmpty)
    }
}

@Suite("Detector reading log")
struct DetectorReadingLogTests {
    @Test("Stable BPM keeps original log timestamp")
    @MainActor
    func preservesTimestampForStableBPM() async {
        let model = DetectorViewModel()
        let first = Date(timeIntervalSince1970: 10_000)
        model.logReadingForTesting(primaryBPM: 120, confidence: 0.5, loggedAt: first)
        model.logReadingForTesting(primaryBPM: 122, confidence: 0.6, loggedAt: Date(timeIntervalSince1970: 20_000))
        #expect(model.loggedReading?.loggedAt == first)
        #expect(model.loggedReading?.primaryBPM == 120)
    }

    @Test("Large BPM change starts a new log entry")
    @MainActor
    func newTimestampWhenBPMChanges() async {
        let model = DetectorViewModel()
        let first = Date(timeIntervalSince1970: 10_000)
        let second = Date(timeIntervalSince1970: 20_000)
        model.logReadingForTesting(primaryBPM: 120, confidence: 0.5, loggedAt: first)
        model.logReadingForTesting(primaryBPM: 90, confidence: 0.6, loggedAt: second)
        #expect(model.loggedReading?.loggedAt == second)
        #expect(model.loggedReading?.primaryBPM == 90)
    }
}
