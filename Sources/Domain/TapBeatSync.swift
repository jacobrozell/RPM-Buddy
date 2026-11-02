import Foundation

/// A tempo chosen by tapping along, plus the beat the pulse should flash on.
struct BeatSyncLock: Equatable, Sendable {
    let bpm: Int
    /// The last tap, or the downbeat kept when the count is stepped.
    let phaseAnchor: Date
    /// True when the count is a half, primary, or double of a microphone reading.
    let usedMicrophone: Bool
    /// The count the taps themselves produced, kept so a later mic reading can still snap.
    let tapBPM: Int
    /// The unshifted pulse. Too slow / Too fast walk this family instead of halving whatever is on screen.
    let pulseBPM: Int
    /// True after Too slow / Too fast. The mic must not pull the count back.
    let holdsCount: Bool
}

struct FeltBeat: Equatable, Sendable {
    let bpm: Int
    let anchor: Date
}

enum BeatSyncHint: Equatable, Sendable {
    case keepTapping
    case synced
    case countedFromTaps
    case countLocked
}

/// When the next haptic tick should land. A downbeat that just happened waits one full period so it does not fire twice.
enum BeatPulseSchedule {
    static func nextDownbeat(bpm: Int, anchor: Date, after now: Date) -> Date {
        let period = 60.0 / Double(max(bpm, 1))
        var phase = now.timeIntervalSince(anchor).truncatingRemainder(dividingBy: period)
        if phase < 0 { phase += period }
        let remaining = phase < 0.04 ? period : period - phase
        return now.addingTimeInterval(min(max(remaining, 0.05), period))
    }
}

/// Steps to the next slower or faster count in one pulse family.
enum OctaveCount {
    static func step(from bpm: Int, pulse: Int, faster: Bool) -> Int? {
        let options = TempoInterpretations.alternatives(for: pulse).map(\.bpm)
        guard let current = options.min(by: { abs($0 - bpm) < abs($1 - bpm) }),
              let index = options.firstIndex(of: current) else {
            return nil
        }
        let nextIndex: [Int].Index
        if faster {
            nextIndex = options.index(after: index)
            guard nextIndex < options.endIndex else { return nil }
        } else {
            guard index > options.startIndex else { return nil }
            nextIndex = options.index(before: index)
        }
        let next = options[nextIndex]
        return next == bpm ? nil : next
    }
}

/// Turns a short run of taps into a BPM, then prefers the microphone's related count when one is close.
enum TapBeatSync {
    static let minimumTaps = 3
    static let minInterval: TimeInterval = 0.24
    static let maxInterval: TimeInterval = 1.55
    static let sequenceGap: TimeInterval = 2
    private static let displayMinBPM = 40
    private static let displayMaxBPM = 240
    private static let snapToleranceBPM = 8
    private static let snapToleranceRatio = 0.12

    static func trailingCluster(_ taps: [Date]) -> [Date] {
        guard var cursor = taps.last else { return [] }
        var cluster = [cursor]
        for tap in taps.dropLast().reversed() {
            if cursor.timeIntervalSince(tap) > sequenceGap { break }
            cluster.append(tap)
            cursor = tap
        }
        return cluster.reversed()
    }

    static func intervals(from taps: [Date]) -> [TimeInterval] {
        let cluster = trailingCluster(taps)
        guard cluster.count >= 2 else { return [] }
        return zip(cluster, cluster.dropFirst()).map { earlier, later in
            later.timeIntervalSince(earlier)
        }
    }

    /// Median gap of a steady run. Wild gaps and fewer than two intervals return nil.
    static func tapBPM(from taps: [Date]) -> Int? {
        let gaps = intervals(from: taps).filter { (minInterval...maxInterval).contains($0) }
        guard gaps.count >= minimumTaps - 1 else { return nil }
        let sorted = gaps.sorted()
        let median = sorted[sorted.count / 2]
        let kept = gaps.filter { abs($0 - median) / median <= 0.2 }.sorted()
        guard kept.count >= minimumTaps - 1 else { return nil }
        let chosen = kept[kept.count / 2]
        let bpm = Int((60.0 / chosen).rounded())
        guard (displayMinBPM...displayMaxBPM).contains(bpm) else { return nil }
        return bpm
    }

    /// Picks the microphone octave nearest the taps when it is close, otherwise the tap count itself.
    static func resolve(tapBPM: Int, detectedBPM: Int?) -> (bpm: Int, usedMicrophone: Bool) {
        guard let detectedBPM else { return (tapBPM, false) }
        let candidates = [0.25, 0.5, 1.0, 2.0].compactMap { factor -> Int? in
            let bpm = Int((Double(detectedBPM) * factor).rounded())
            guard (displayMinBPM...displayMaxBPM).contains(bpm) else { return nil }
            return bpm
        }
        guard let best = candidates.min(by: { abs($0 - tapBPM) < abs($1 - tapBPM) }) else {
            return (tapBPM, false)
        }
        let delta = abs(best - tapBPM)
        let ratio = Double(delta) / Double(max(tapBPM, 1))
        if delta <= snapToleranceBPM || ratio <= snapToleranceRatio {
            return (best, true)
        }
        return (tapBPM, false)
    }
}
