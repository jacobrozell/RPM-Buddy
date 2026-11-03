import AVFoundation
import Foundation

enum LiveCaptureError: Error {
    case microphoneBusy
}

/// Captures microphone PCM into a rolling buffer for periodic tempo analysis.
final class LiveAudioCapture: @unchecked Sendable {
    private enum SessionError: Error {
        case activationFailed
    }

    private let engine = AVAudioEngine()
    private let queue = DispatchQueue(label: "com.jacobrozell.rpmbuddy.capture")
    private var ringBuffer: [Float] = []
    private var writeIndex = 0
    private var filledCount = 0
    private let capacity: Int
    private var latestLevel: Float = 0
    private var cachedSampleRate: Double = 48_000
    private var didActivateSession = false
    private var wantsEngine = false
    private var isConfiguringEngine = false
    private var tapInstalled = false
    private var configObserver: NSObjectProtocol?

    var sampleRate: Double {
        queue.sync { cachedSampleRate }
    }

    var inputLevel: Float {
        queue.sync { latestLevel }
    }

    init(maxSeconds: Double = 18) {
        let rate = 48_000.0
        capacity = max(1, Int(rate * maxSeconds))
        ringBuffer = [Float](repeating: 0, count: capacity)
    }

    @MainActor
    func start() async throws {
        try await Self.prepareSession()
        didActivateSession = true
        wantsEngine = true
        installConfigurationObserver()
        do {
            try await startEngine()
        } catch {
            await stop()
            throw error
        }
    }

    @MainActor
    func stop() async {
        wantsEngine = false
        if let configObserver {
            NotificationCenter.default.removeObserver(configObserver)
            self.configObserver = nil
        }
        removeInstalledTap()
        if engine.isRunning {
            engine.stop()
        }
        guard didActivateSession else { return }
        didActivateSession = false
        await Self.deactivateSession()
    }

    func recentSamples(maxSeconds: Double) -> [Float] {
        queue.sync {
            guard filledCount > 0 else { return [] }
            let requested = min(filledCount, Int(cachedSampleRate * maxSeconds))
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

    private static func prepareSession() async throws {
        try await Task.detached {
            let session = AVAudioSession.sharedInstance()
            let options: AVAudioSession.CategoryOptions = [
                .defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP
            ]
            try session.setCategory(.playAndRecord, mode: .default, options: options)
            try? session.setAllowHapticsAndSystemSoundsDuringRecording(true)
            if #available(iOS 27.0, *) {
                try await activate(session)
            } else {
                try session.setActive(true)
            }
        }.value
    }

    @available(iOS 27.0, *)
    private static func activate(_ session: AVAudioSession) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            session.activate(options: []) { activated, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if activated {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: SessionError.activationFailed)
                }
            }
        }
    }

    private static func deactivateSession() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await Self.deactivateNow() }
            group.addTask {
                try? await Task.sleep(for: .seconds(1))
            }
            await group.next()
            group.cancelAll()
        }
    }

    private static func deactivateNow() async {
        await Task.detached {
            let session = AVAudioSession.sharedInstance()
            if #available(iOS 27.0, *) {
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    session.deactivate(options: [.notifyOthersOnDeactivation]) { _, _ in
                        continuation.resume()
                    }
                }
            } else {
                try? session.setActive(false, options: [.notifyOthersOnDeactivation])
            }
        }.value
    }

    @MainActor
    private func installConfigurationObserver() {
        guard configObserver == nil else { return }
        configObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                guard let self, self.wantsEngine, !self.engine.isRunning, !self.isConfiguringEngine else { return }
                try? await self.startEngine()
            }
        }
    }

    @MainActor
    private func startEngine() async throws {
        guard !isConfiguringEngine else { return }
        isConfiguringEngine = true
        defer { isConfiguringEngine = false }

        removeInstalledTap()
        if engine.isRunning {
            engine.stop()
        }
        let input = try audioNode { self.engine.inputNode }
        _ = RPMCatchAudioException {
            _ = try? input.setVoiceProcessingEnabled(false)
            self.engine.mainMixerNode.outputVolume = 0
        }
        guard let format = await resolvedInputFormat(input) else {
            throw LiveCaptureError.microphoneBusy
        }
        queue.sync { cachedSampleRate = format.sampleRate }
        try performAudio {
            input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
                self?.append(buffer: buffer)
            }
        }
        tapInstalled = true
        try performAudio { self.engine.prepare() }
        var startError: Error?
        try performAudio {
            do {
                try self.engine.start()
            } catch {
                startError = error
            }
        }
        if let startError {
            throw startError
        }
    }

    @MainActor
    private func removeInstalledTap() {
        guard tapInstalled else { return }
        tapInstalled = false
        _ = RPMCatchAudioException {
            self.engine.inputNode.removeTap(onBus: 0)
        }
    }

    @MainActor
    private func audioNode<T>(_ body: () -> T) throws -> T {
        var value: T?
        try performAudio { value = body() }
        guard let value else { throw LiveCaptureError.microphoneBusy }
        return value
    }

    @MainActor
    private func performAudio(_ body: () -> Void) throws {
        if RPMCatchAudioException(body) != nil {
            throw LiveCaptureError.microphoneBusy
        }
    }

    @MainActor
    private func resolvedInputFormat(_ input: AVAudioInputNode) async -> AVAudioFormat? {
        for _ in 0..<5 {
            var format: AVAudioFormat?
            if (try? performAudio { format = input.outputFormat(forBus: 0) }) != nil,
               let format,
               format.sampleRate > 0,
               format.channelCount > 0 {
                return format
            }
            try? await Task.sleep(for: .milliseconds(40))
        }
        return nil
    }

    private func append(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        let channels = Int(buffer.format.channelCount)
        guard channels > 0 else { return }
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        queue.async {
            var blockSum: Float = 0
            for sample in samples {
                self.ringBuffer[self.writeIndex] = sample
                self.writeIndex = (self.writeIndex + 1) % self.capacity
                self.filledCount = min(self.capacity, self.filledCount + 1)
                blockSum += sample * sample
            }
            self.latestLevel = min(1, (blockSum / Float(frameLength)).squareRoot() * 8)
        }
    }
}
