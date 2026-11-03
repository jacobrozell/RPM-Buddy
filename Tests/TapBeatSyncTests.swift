import Foundation
import Testing
@testable import RPMBuddy

@Suite("Tap beat sync")
struct TapBeatSyncTests {
    private func taps(start: TimeInterval = 1_000, gaps: [TimeInterval]) -> [Date] {
        var cursor = start
        var dates = [Date(timeIntervalSince1970: cursor)]
        for gap in gaps {
            cursor += gap
            dates.append(Date(timeIntervalSince1970: cursor))
        }
        return dates
    }

    @Test("Steady half-second taps are 120 BPM")
    func steady120() {
        let bpm = TapBeatSync.tapBPM(from: taps(gaps: [0.5, 0.5, 0.5]))
        #expect(bpm == 120)
    }

    @Test("A stray gap is ignored")
    func ignoresOutlier() {
        let bpm = TapBeatSync.tapBPM(from: taps(gaps: [0.5, 0.5, 1.2, 0.5]))
        #expect(bpm == 120)
    }

    @Test("Two taps are not enough")
    func needsThreeTaps() {
        #expect(TapBeatSync.tapBPM(from: taps(gaps: [0.5])) == nil)
    }

    @Test("A long pause starts a new run")
    func pauseStartsNewRun() {
        let dates = taps(gaps: [0.5, 0.5, 3, 0.75, 0.75])
        #expect(TapBeatSync.tapBPM(from: dates) == 80)
    }

    @Test("160 BPM mic reading snaps to an 80 BPM tap")
    func snapsDoubleTimeDown() {
        let resolved = TapBeatSync.resolve(tapBPM: 82, detectedBPM: 160)
        #expect(resolved.bpm == 80)
        #expect(resolved.usedMicrophone)
    }

    @Test("85 BPM mic reading snaps up to a 170 BPM tap")
    func snapsHalfTimeUp() {
        let resolved = TapBeatSync.resolve(tapBPM: 168, detectedBPM: 85)
        #expect(resolved.bpm == 170)
        #expect(resolved.usedMicrophone)
    }

    @Test("Taps near the mic reading keep the mic count")
    func keepsMicPrecision() {
        let resolved = TapBeatSync.resolve(tapBPM: 118, detectedBPM: 120)
        #expect(resolved.bpm == 120)
        #expect(resolved.usedMicrophone)
    }

    @Test("Taps far from every related count stand on their own")
    func keepsUnrelatedTap() {
        let resolved = TapBeatSync.resolve(tapBPM: 100, detectedBPM: 160)
        #expect(resolved.bpm == 100)
        #expect(!resolved.usedMicrophone)
    }

    @Test("160 steps to 80 and back, not past the ends")
    func steps160Family() {
        #expect(OctaveCount.step(from: 160, pulse: 160, faster: false) == 80)
        #expect(OctaveCount.step(from: 80, pulse: 160, faster: true) == 160)
        #expect(OctaveCount.step(from: 80, pulse: 160, faster: false) == 40)
        #expect(OctaveCount.step(from: 160, pulse: 160, faster: true) == nil)
        #expect(OctaveCount.step(from: 40, pulse: 160, faster: false) == nil)
    }

    @Test("Odd tempos stay in one family when stepped back")
    func oddTempoRoundTrip() {
        let slower = OctaveCount.step(from: 85, pulse: 85, faster: false)
        #expect(slower == 43)
        #expect(OctaveCount.step(from: 85, pulse: 85, faster: true) == 170)
        #expect(OctaveCount.step(from: 170, pulse: 85, faster: false) == 85)
        #expect(OctaveCount.step(from: 43, pulse: 85, faster: true) == 85)
    }

    @Test("A downbeat waits one full period before the next tick")
    func downbeatWaitsFullPeriod() {
        let anchor = Date(timeIntervalSince1970: 2_000)
        let next = BeatPulseSchedule.nextDownbeat(bpm: 120, anchor: anchor, after: anchor)
        #expect(abs(next.timeIntervalSince(anchor) - 0.5) < 0.001)
    }

    @Test("Halfway through a beat the tick is the remaining half")
    func halfwayWaitsRemainder() {
        let anchor = Date(timeIntervalSince1970: 2_000)
        let now = anchor.addingTimeInterval(0.25)
        let next = BeatPulseSchedule.nextDownbeat(bpm: 120, anchor: anchor, after: now)
        #expect(abs(next.timeIntervalSince(now) - 0.25) < 0.001)
    }

    @Test("No microphone reading uses the taps")
    func tapOnly() {
        let resolved = TapBeatSync.resolve(tapBPM: 96, detectedBPM: nil)
        #expect(resolved.bpm == 96)
        #expect(!resolved.usedMicrophone)
    }
}

@Suite("Detector tap sync")
struct DetectorTapSyncTests {
    @Test("Taps promote the half-time count and anchor the beat")
    @MainActor
    func snapsLoggedDoubleTime() {
        let model = DetectorViewModel()
        let start = Date(timeIntervalSince1970: 5_000)
        model.logReadingForTesting(primaryBPM: 160, confidence: 0.49, loggedAt: start)
        model.registerTap(at: start)
        model.registerTap(at: start.addingTimeInterval(0.75))
        let anchor = start.addingTimeInterval(1.5)
        model.registerTap(at: anchor)

        #expect(model.beatSync?.bpm == 80)
        #expect(model.beatSync?.usedMicrophone == true)
        #expect(model.beatSync?.phaseAnchor == anchor)
        #expect(model.displayedBPM == 80)
        #expect(model.loggedReading?.primaryBPM == 80)
        #expect(model.loggedReading?.loggedAt == start)
        #expect(model.beatSyncHint == .synced)
    }

    @Test("Taps alone count a tempo when nothing is detected")
    @MainActor
    func countsWithoutDetection() {
        let model = DetectorViewModel()
        let start = Date(timeIntervalSince1970: 8_000)
        model.registerTap(at: start)
        model.registerTap(at: start.addingTimeInterval(0.5))
        #expect(model.beatSync == nil)
        #expect(model.beatSyncHint == .keepTapping)
        model.registerTap(at: start.addingTimeInterval(1.0))
        #expect(model.displayedBPM == 120)
        #expect(model.beatSync?.usedMicrophone == false)
        #expect(model.beatSyncHint == .countedFromTaps)
    }

    @Test("A too-fast extra tap does not change the count")
    @MainActor
    func debouncesDoubleTap() {
        let model = DetectorViewModel()
        let start = Date(timeIntervalSince1970: 9_000)
        model.registerTap(at: start)
        model.registerTap(at: start.addingTimeInterval(0.05))
        model.registerTap(at: start.addingTimeInterval(0.5))
        model.registerTap(at: start.addingTimeInterval(1.0))
        #expect(model.displayedBPM == 120)
        #expect(model.acceptedTapCount == 3)
    }

    @Test("Starting a listen clears the synced beat")
    @MainActor
    func listenClearsSync() async {
        let model = DetectorViewModel()
        let start = Date(timeIntervalSince1970: 11_000)
        model.registerTap(at: start)
        model.registerTap(at: start.addingTimeInterval(0.5))
        model.registerTap(at: start.addingTimeInterval(1.0))
        #expect(model.beatSync != nil)
        await model.startListening()
        #expect(model.beatSync == nil)
        #expect(model.beatSyncHint == nil)
        #expect(model.displayedBPM == nil)
    }

    @Test("Too fast locks the half count and a second press keeps the same family")
    @MainActor
    func locksSlowerCount() {
        let model = DetectorViewModel()
        let start = Date(timeIntervalSince1970: 12_000)
        model.logReadingForTesting(primaryBPM: 160, confidence: 0.5, loggedAt: start)
        #expect(model.countStep(faster: false) == 80)
        #expect(model.countStep(faster: true) == nil)
        model.stepCount(faster: false, at: start)

        #expect(model.displayedBPM == 80)
        #expect(model.beatSync?.holdsCount == true)
        #expect(model.beatSync?.pulseBPM == 160)
        #expect(model.beatSync?.phaseAnchor == start)
        #expect(model.beatSyncHint == .countLocked)
        #expect(model.loggedReading?.loggedAt == start)

        model.stepCount(faster: false, at: start.addingTimeInterval(1))
        #expect(model.displayedBPM == 40)
        #expect(model.beatSync?.pulseBPM == 160)
        model.stepCount(faster: true, at: start.addingTimeInterval(2))
        #expect(model.displayedBPM == 80)
    }

    @Test("Taps after a count lock only move the downbeat")
    @MainActor
    func tapsDoNotReleaseCountLock() {
        let model = DetectorViewModel()
        let start = Date(timeIntervalSince1970: 13_000)
        model.logReadingForTesting(primaryBPM: 160, confidence: 0.5, loggedAt: start)
        model.stepCount(faster: false, at: start)
        let later = start.addingTimeInterval(4)
        model.registerTap(at: later)
        model.registerTap(at: later.addingTimeInterval(0.5))
        model.registerTap(at: later.addingTimeInterval(1.0))

        #expect(model.displayedBPM == 80)
        #expect(model.beatSync?.holdsCount == true)
        #expect(model.beatSync?.pulseBPM == 160)
        #expect(model.beatSync?.phaseAnchor == later.addingTimeInterval(1.0))
        #expect(model.beatSyncHint == .countLocked)
    }

    @Test("Later taps keep the original microphone pulse family")
    @MainActor
    func laterTapsKeepPulseFamily() {
        let model = DetectorViewModel()
        let start = Date(timeIntervalSince1970: 14_000)
        model.logReadingForTesting(primaryBPM: 177, confidence: 0.4, loggedAt: start)
        let gap = 60.0 / 89.0
        model.registerTap(at: start)
        model.registerTap(at: start.addingTimeInterval(gap))
        model.registerTap(at: start.addingTimeInterval(gap * 2))
        model.registerTap(at: start.addingTimeInterval(gap * 3))

        #expect(model.beatSync?.bpm == 89)
        #expect(model.beatSync?.pulseBPM == 177)
        #expect(model.countStep(faster: true) == 177)
    }

    @Test("Stepping a tap-only count does not claim a microphone reading")
    @MainActor
    func stepKeepsTapOnlySource() {
        let model = DetectorViewModel()
        let start = Date(timeIntervalSince1970: 15_000)
        model.registerTap(at: start)
        model.registerTap(at: start.addingTimeInterval(0.5))
        model.registerTap(at: start.addingTimeInterval(1.0))
        model.stepCount(faster: false, at: start.addingTimeInterval(2))

        #expect(model.displayedBPM == 60)
        #expect(model.beatSync?.usedMicrophone == false)
        #expect(model.beatSync?.holdsCount == true)
    }

    @Test("A later microphone reading cannot pull a locked count back")
    @MainActor
    func micCannotOverrideLockedCount() {
        let model = DetectorViewModel()
        let start = Date(timeIntervalSince1970: 16_000)
        model.logReadingForTesting(primaryBPM: 160, confidence: 0.5, loggedAt: start)
        model.stepCount(faster: false, at: start)
        model.applyEstimateForTesting(bpm: 160, confidence: 0.9)

        #expect(model.displayedBPM == 80)
        #expect(model.beatSync?.holdsCount == true)
        #expect(model.loggedReading?.primaryBPM == 80)
        #expect(model.loggedReading?.confidence == 0.9)
    }

    @Test("The pulse ticks once per beat and not twice on the same downbeat")
    @MainActor
    func pulseTicksOncePerBeat() {
        let model = DetectorViewModel()
        let start = Date(timeIntervalSince1970: 17_000)
        model.logReadingForTesting(primaryBPM: 160, confidence: 0.5, loggedAt: start)
        model.stepCount(faster: false, at: start)
        model.enableListeningForTesting()

        model.advancePulse(to: start)
        #expect(model.beatTick == 0)
        model.advancePulse(to: start.addingTimeInterval(0.75))
        #expect(model.beatTick == 1)
        model.advancePulse(to: start.addingTimeInterval(0.75))
        #expect(model.beatTick == 1)
        model.advancePulse(to: start.addingTimeInterval(1.5))
        #expect(model.beatTick == 2)
    }

    @Test("Stop ends the pulse and keeps the scan")
    @MainActor
    func stopEndsPulseAndKeepsScan() async {
        let model = DetectorViewModel(scanHistory: MemoryScanHistoryStore())
        let start = Date(timeIntervalSince1970: 19_000)
        model.logReadingForTesting(primaryBPM: 100, confidence: 0.6, loggedAt: start)
        model.stepCount(faster: false, at: start)
        model.enableListeningForTesting()
        #expect(model.showsPulse)

        model.advancePulse(to: start.addingTimeInterval(1.2))
        let ticks = model.beatTick
        await model.stopListening()

        #expect(!model.isListening)
        #expect(!model.showsPulse)
        model.advancePulse(to: start.addingTimeInterval(4))
        #expect(model.beatTick == ticks)
        #expect(model.scans.count == 1)
        #expect(model.scans[0].bpm == model.displayedBPM)
        await model.stopListening()
        #expect(model.scans.count == 1)
    }

    @Test("A second listen tap does nothing while the mic is changing")
    @MainActor
    func ignoresToggleWhileListenIsChanging() async {
        let model = DetectorViewModel(scanHistory: MemoryScanHistoryStore())
        let start = Date(timeIntervalSince1970: 21_000)
        model.logReadingForTesting(primaryBPM: 90, confidence: 0.4, loggedAt: start)
        model.enableListeningForTesting()
        model.setChangingListenForTesting(true)

        await model.toggleListening()
        await model.startListening()

        #expect(model.isListening)
        #expect(model.loggedReading?.primaryBPM == 90)
        #expect(model.scans.isEmpty)
    }

    @Test("The pulse does not tick while listening is off")
    @MainActor
    func pulseStaysQuietUntilListening() {
        let model = DetectorViewModel()
        let start = Date(timeIntervalSince1970: 18_000)
        model.logReadingForTesting(primaryBPM: 120, confidence: 0.5, loggedAt: start)
        model.advancePulse(to: start.addingTimeInterval(2))
        #expect(model.beatTick == 0)
    }
}
