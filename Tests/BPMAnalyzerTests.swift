import Testing
@testable import RPMBuddy

@Suite("BPM Analyzer")
struct BPMAnalyzerTests {
    private let sampleRate = BPMAnalyzer.analysisSampleRate

    private func clickTrack(bpm: Double, seconds: Double) -> [Float] {
        let count = Int(seconds * sampleRate)
        var samples = [Float](repeating: 0, count: count)
        let period = Int(60.0 / bpm * sampleRate)
        var index = 0
        while index < count {
            for offset in index..<min(index + 128, count) { samples[offset] = 1 }
            index += period
        }
        return samples
    }

    @Test("Detects 120 BPM click track with usable confidence")
    func detects120BPM() {
        let result = BPMAnalyzer.estimate(samples: clickTrack(bpm: 120, seconds: 20), sampleRate: sampleRate)
        #expect(result.bpm != nil)
        if let bpm = result.bpm {
            #expect(abs(bpm - 120) <= 3)
        }
        #expect(result.confidence > 0.2)
    }

    @Test("Detects 90 BPM click track")
    func detects90BPM() {
        let result = BPMAnalyzer.estimate(samples: clickTrack(bpm: 90, seconds: 20), sampleRate: sampleRate)
        #expect(result.bpm != nil)
        if let bpm = result.bpm {
            #expect(abs(bpm - 90) <= 3)
        }
    }

    @Test("Silence yields no BPM")
    func silenceHasNoBPM() {
        let silence = [Float](repeating: 0, count: 20_000)
        let result = BPMAnalyzer.estimate(samples: silence, sampleRate: sampleRate)
        #expect(result.bpm == nil)
        #expect(result.confidence == 0)
    }

    @Test("White noise yields no BPM")
    func noiseHasNoBPM() {
        var state: UInt64 = 7
        let noise = (0..<Int(12 * sampleRate)).map { _ -> Float in
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Float(state >> 40) / Float(1 << 24) - 0.5
        }
        let result = BPMAnalyzer.estimate(samples: noise, sampleRate: sampleRate)
        #expect(result.bpm == nil)
    }

    @Test("Decimation preserves enough samples for analysis")
    func decimation() {
        let source = clickTrack(bpm: 128, seconds: 4)
        let prepared = BPMAnalyzer.prepareSamples(source, sourceRate: 48_000)
        #expect(!prepared.isEmpty)
        #expect(prepared.count < source.count)
    }

    @Test("48 kHz decimation uses effective sample rate for accurate BPM")
    func decimated48kHzTempo() {
        let sourceRate = 48_000.0
        let seconds = 20.0
        let count = Int(seconds * sourceRate)
        var samples = [Float](repeating: 0, count: count)
        let bpm = 120.0
        let period = Int(60.0 / bpm * sourceRate)
        var index = 0
        while index < count {
            for offset in index..<min(index + 640, count) { samples[offset] = 0.9 }
            index += period
        }

        let prepared = BPMAnalyzer.prepareSamples(samples, sourceRate: sourceRate)
        let normalized = AudioLevelNormalizer.normalize(prepared)
        let analysisRate = BPMAnalyzer.effectiveSampleRate(sourceRate: sourceRate)
        let result = BPMAnalyzer.estimate(samples: normalized, sampleRate: analysisRate)

        #expect(result.bpm != nil)
        if let detected = result.bpm {
            #expect(abs(detected - 120) <= 3)
        }
    }
}
