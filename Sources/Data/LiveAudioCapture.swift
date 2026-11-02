import AVFoundation
import Foundation

/// Captures microphone PCM into a rolling buffer for periodic tempo analysis.
final class LiveAudioCapture: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private let queue = DispatchQueue(label: "com.jacobrozell.rpmbuddy.capture")
    private var ringBuffer: [Float] = []
    private var writeIndex = 0
    private var filledCount = 0
    private let capacity: Int
    private var latestLevel: Float = 0

    var sampleRate: Double {
        engine.inputNode.outputFormat(forBus: 0).sampleRate
    }

    var inputLevel: Float {
        queue.sync { latestLevel }
    }

    init(maxSeconds: Double = 18) {
        let rate = 48_000.0
        capacity = max(1, Int(rate * maxSeconds))
        ringBuffer = [Float](repeating: 0, count: capacity)
    }

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .mixWithOthers])
        try session.setActive(true)

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            self?.append(buffer: buffer)
        }
        engine.prepare()
        try engine.start()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func recentSamples(maxSeconds: Double) -> [Float] {
        queue.sync {
            guard filledCount > 0 else { return [] }
            let requested = min(filledCount, Int(sampleRate * maxSeconds))
            var output = [Float]()
            output.reserveCapacity(requested)
            var readIndex = (writeIndex - requested + capacity) % capacity
            for _ in 0..<requested {
                output.append(ringBuffer[readIndex])
                readIndex = (readIndex + 1) % capacity
            }
            return output
        }
    }

    private func append(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        let channels = Int(buffer.format.channelCount)
        let mono = (0..<frameLength).map { frame -> Float in
            var sample: Float = 0
            for channel in 0..<channels {
                sample += channelData[channel][frame]
            }
            return sample / Float(channels)
        }
        queue.async {
            var blockSum: Float = 0
            for sample in mono {
                self.ringBuffer[self.writeIndex] = sample
                self.writeIndex = (self.writeIndex + 1) % self.capacity
                self.filledCount = min(self.capacity, self.filledCount + 1)
                blockSum += sample * sample
            }
            self.latestLevel = min(1, (blockSum / Float(frameLength)).squareRoot() * 8)
        }
    }
}
