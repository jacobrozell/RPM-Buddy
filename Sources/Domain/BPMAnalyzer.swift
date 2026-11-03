import Accelerate
import Foundation

/// Result of tempo analysis with a transparent confidence score (0…1).
struct BPMEstimate: Sendable, Equatable {
    let bpm: Int?
    let confidence: Double

    static let silent = BPMEstimate(bpm: nil, confidence: 0)
}

/// Tempo estimator after librosa's `beat.tempo`: a log-mel spectral flux onset envelope,
/// a windowed autocorrelation averaged over time, and a log-normal prior centered on 120 BPM.
/// Each candidate period also scores its first few multiples, so the beat that the whole
/// rhythm lines up with wins over a single strong off-grid repetition.
enum BPMAnalyzer {
    static let analysisSampleRate = 11_025.0

    private static let minBPM = 40.0
    private static let maxBPM = 180.0
    private static let fftSize = 1024
    private static let hopSize = 128
    private static let melBandCount = 40
    private static let logCompression: Float = 1_000
    private static let combMultiples = 4
    private static let tempogramSeconds = 8.0
    private static let priorCenterBPM = 120.0
    private static let priorOctaveWidth = 1.0
    /// Periodicity of pure room noise lands near 0.06; clear grooves reach 0.3–0.6.
    private static let noisePeriodicity = 0.05
    private static let clearPeriodicity = 0.5
    private static let minimumConfidence = 0.08

    static func estimate(samples: [Float], sampleRate: Double) -> BPMEstimate {
        guard sampleRate > 0, signalRMS(samples) > 0.000_25,
              let onset = onsetEnvelope(samples: samples, sampleRate: sampleRate) else {
            return .silent
        }

        let framesPerSecond = sampleRate / Double(hopSize)
        let minLag = Int((60 * framesPerSecond / maxBPM).rounded(.down))
        let maxLag = Int((60 * framesPerSecond / minBPM).rounded(.up))
        guard onset.count >= maxLag * 3 else { return .silent }

        let correlation = meanAutocorrelation(
            onset: onset,
            maxLag: (maxLag + 1) * combMultiples,
            windowLength: Int(tempogramSeconds * framesPerSecond),
            step: Int(framesPerSecond)
        )
        let scores = (0...(maxLag + 1)).map { lag -> Float in
            guard lag > 0 else { return 0 }
            let comb = (1...combMultiples).reduce(Float(0)) { sum, multiple in
                sum + correlation[lag * multiple] / Float(multiple)
            }
            return comb * prior(bpm: 60 * framesPerSecond / Double(lag))
        }
        guard let bestLag = (minLag...maxLag).max(by: { scores[$0] < scores[$1] }),
              scores[bestLag] > 0 else {
            return BPMEstimate(bpm: nil, confidence: 0)
        }

        let bpm = 60 * framesPerSecond / parabolicPeak(scores, at: bestLag)
        let periodicity = Double(correlation[bestLag])
        let confidence = min(1, max(0, (periodicity - noisePeriodicity) / (clearPeriodicity - noisePeriodicity)))
        guard confidence >= minimumConfidence else {
            return BPMEstimate(bpm: nil, confidence: confidence)
        }
        return BPMEstimate(bpm: Int(bpm.rounded()), confidence: confidence)
    }

    static func effectiveSampleRate(sourceRate: Double) -> Double {
        guard sourceRate > 0 else { return analysisSampleRate }
        let factor = max(1, Int((sourceRate / analysisSampleRate).rounded()))
        return sourceRate / Double(factor)
    }

    static func prepareSamples(_ samples: [Float], sourceRate: Double) -> [Float] {
        guard sourceRate > 0, !samples.isEmpty else { return [] }
        let factor = max(1, Int((sourceRate / analysisSampleRate).rounded()))
        guard factor > 1 else { return samples }

        var decimated = [Float]()
        decimated.reserveCapacity(samples.count / factor + 1)
        var index = 0
        while index < samples.count {
            let end = min(index + factor, samples.count)
            decimated.append(vDSP.mean(samples[index..<end]))
            index += factor
        }
        return decimated
    }

    // MARK: - Onset envelope

    /// Mean positive change in log-compressed mel energy per frame, so quiet bands still count.
    private static func onsetEnvelope(samples: [Float], sampleRate: Double) -> [Float]? {
        guard samples.count >= fftSize * 2 else { return nil }
        let frameCount = (samples.count - fftSize) / hopSize + 1
        let half = fftSize / 2
        let log2Size = vDSP_Length(log2(Double(fftSize)))
        guard let fft = vDSP.FFT(log2n: log2Size, radix: .radix2, ofType: DSPSplitComplex.self) else {
            return nil
        }

        let window = vDSP.window(
            ofType: Float.self, usingSequence: .hanningDenormalized, count: fftSize, isHalfWindow: false
        )
        let filters = melFilterbank(binCount: half + 1, sampleRate: sampleRate)
        var mel = [Float](repeating: 0, count: frameCount * melBandCount)
        var frame = [Float](repeating: 0, count: fftSize)
        var real = [Float](repeating: 0, count: half)
        var imag = [Float](repeating: 0, count: half)
        var power = [Float](repeating: 0, count: half + 1)

        for frameIndex in 0..<frameCount {
            let start = frameIndex * hopSize
            vDSP.multiply(samples[start..<(start + fftSize)], window, result: &frame)
            real.withUnsafeMutableBufferPointer { realBuffer in
                imag.withUnsafeMutableBufferPointer { imagBuffer in
                    var split = DSPSplitComplex(realp: realBuffer.baseAddress!, imagp: imagBuffer.baseAddress!)
                    frame.withUnsafeBytes { bytes in
                        vDSP_ctoz(bytes.bindMemory(to: DSPComplex.self).baseAddress!, 2, &split, 1, vDSP_Length(half))
                    }
                    fft.forward(input: split, output: &split)
                    let nyquist = split.imagp[0]
                    split.imagp[0] = 0
                    vDSP_zvmags(&split, 1, &power, 1, vDSP_Length(half))
                    power[half] = nyquist * nyquist
                }
            }
            mel.withUnsafeMutableBufferPointer { melBuffer in
                vDSP_mmul(
                    power, 1, filters, 1,
                    melBuffer.baseAddress! + frameIndex * melBandCount, 1,
                    1, vDSP_Length(melBandCount), vDSP_Length(half + 1)
                )
            }
        }

        let peak = max(vDSP.maximum(mel), 1e-12)
        let compressed = vForce.log10(vDSP.add(1, vDSP.multiply(logCompression / peak, mel)))

        var onset = [Float](repeating: 0, count: frameCount)
        for frameIndex in 1..<frameCount {
            let current = frameIndex * melBandCount
            let previous = current - melBandCount
            var rise: Float = 0
            for band in 0..<melBandCount {
                rise += max(0, compressed[current + band] - compressed[previous + band])
            }
            onset[frameIndex] = rise / Float(melBandCount)
        }
        return onset
    }

    /// Triangular mel filters, row-major `binCount × melBandCount`.
    private static func melFilterbank(binCount: Int, sampleRate: Double) -> [Float] {
        func mel(_ hz: Double) -> Double { 2595 * log10(1 + hz / 700) }
        func hz(_ mel: Double) -> Double { 700 * (pow(10, mel / 2595) - 1) }

        let low = mel(30)
        let high = mel(sampleRate / 2)
        let edges = (0...(melBandCount + 1)).map {
            hz(low + (high - low) * Double($0) / Double(melBandCount + 1))
        }
        let binHz = sampleRate / Double(fftSize)

        var filters = [Float](repeating: 0, count: binCount * melBandCount)
        for band in 0..<melBandCount {
            let (left, center, right) = (edges[band], edges[band + 1], edges[band + 2])
            for bin in 0..<binCount {
                let frequency = Double(bin) * binHz
                let weight = frequency <= center
                    ? (frequency - left) / (center - left)
                    : (right - frequency) / (right - center)
                if weight > 0 { filters[bin * melBandCount + band] = Float(weight) }
            }
        }
        return filters
    }

    // MARK: - Tempo

    /// Normalized autocorrelation of overlapping Hann-windowed segments, averaged over time.
    private static func meanAutocorrelation(
        onset: [Float], maxLag: Int, windowLength: Int, step: Int
    ) -> [Float] {
        let length = min(onset.count, windowLength)
        let taper = vDSP.window(
            ofType: Float.self, usingSequence: .hanningDenormalized, count: length, isHalfWindow: false
        )
        var total = [Float](repeating: 0, count: maxLag + 1)
        var windows = 0

        var start = 0
        while start + length <= onset.count {
            let segment = onset[start..<(start + length)]
            let centered = vDSP.multiply(vDSP.add(-vDSP.mean(segment), segment), taper)
            let energy = vDSP.sumOfSquares(centered)
            if energy > 1e-9 {
                for lag in 0...maxLag where lag < length {
                    total[lag] += vDSP.dot(centered[lag...], centered[..<(length - lag)]) / energy
                }
                windows += 1
            }
            start += max(1, step)
        }
        guard windows > 0 else { return total }
        return vDSP.divide(total, Float(windows))
    }

    private static func prior(bpm: Double) -> Float {
        let octaves = log2(bpm / priorCenterBPM) / priorOctaveWidth
        return Float(exp(-0.5 * octaves * octaves))
    }

    private static func parabolicPeak(_ values: [Float], at index: Int) -> Double {
        guard index > 0, index + 1 < values.count else { return Double(index) }
        let (left, center, right) = (values[index - 1], values[index], values[index + 1])
        let denominator = left - 2 * center + right
        guard abs(denominator) > 1e-12 else { return Double(index) }
        return Double(index) + min(0.5, max(-0.5, 0.5 * Double(left - right) / Double(denominator)))
    }

    private static func signalRMS(_ samples: [Float]) -> Double {
        guard !samples.isEmpty else { return 0 }
        return Double(vDSP.rootMeanSquare(samples))
    }
}
