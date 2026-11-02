import Testing
@testable import RPMBuddy

@Suite("Audio level normalization")
struct AudioLevelNormalizerTests {
    private let sampleRate = BPMAnalyzer.analysisSampleRate

    private func clickTrack(bpm: Double, seconds: Double, amplitude: Float) -> [Float] {
        let count = Int(seconds * sampleRate)
        var samples = [Float](repeating: 0, count: count)
        let period = Int(60.0 / bpm * sampleRate)
        var index = 0
        while index < count {
            for offset in index..<min(index + 128, count) { samples[offset] = amplitude }
            index += period
        }
        return samples
    }

    @Test("Quiet click track detects after normalization")
    func quietClickTrack() {
        let quiet = clickTrack(bpm: 120, seconds: 20, amplitude: 0.02)
        let normalized = AudioLevelNormalizer.normalize(quiet)
        let result = BPMAnalyzer.estimate(samples: normalized, sampleRate: sampleRate)
        #expect(result.bpm != nil)
        if let bpm = result.bpm {
            #expect(abs(bpm - 120) <= 3)
        }
    }

    @Test("Silence is not boosted into false signal")
    func silenceUnchanged() {
        let silence = [Float](repeating: 0, count: 10_000)
        let normalized = AudioLevelNormalizer.normalize(silence)
        let result = BPMAnalyzer.estimate(samples: normalized, sampleRate: sampleRate)
        #expect(result.bpm == nil)
    }
}
