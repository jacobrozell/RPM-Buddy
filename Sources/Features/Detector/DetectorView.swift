import SwiftUI

struct DetectorView: View {
    @Bindable var model: DetectorViewModel
    @State private var showsSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    bpmCard
                    listenButton
                    meters
                    tapBeatButton
                    countStepButtons
                    Text(hint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, minHeight: 34, alignment: .top)
                        .accessibilityIdentifier(A11yID.beatSyncHint)
                    if let reading = model.loggedReading {
                        loggedSection(reading)
                    }
                    scanHistory
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .navigationTitle("RPM Buddy")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        AppLogging.logger.info(
                            .settings,
                            eventName: "settings_opened",
                            message: "Opened settings."
                        )
                        showsSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(String(localized: "settings.open", defaultValue: "Settings"))
                    .accessibilityIdentifier(A11yID.settingsButton)
                }
            }
            .sheet(isPresented: $showsSettings) {
                SettingsView()
            }
        }
    }

    private var bpmCard: some View {
        VStack(spacing: 2) {
            Text(bpmText)
                .font(.system(size: 92, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(bpmAccessibilityLabel)
                .accessibilityIdentifier(A11yID.bpmValue)
            Text(String(localized: "detector.bpm.unit", defaultValue: "BPM"))
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(model.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 40, alignment: .top)
                .padding(.top, 8)
        }
        .padding(.top, 28)
        .padding(.bottom, 20)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            if model.showsPulse, let feltBeat = model.feltBeat {
                BeatPulseRing(bpm: feltBeat.bpm, anchor: feltBeat.anchor)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
            }
        }
    }

    private var listenButton: some View {
        Button {
            Task { await model.toggleListening() }
        } label: {
            Label(listenTitle, systemImage: listenSymbol)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 54)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier(A11yID.listenToggle)
    }

    private var listenTitle: String {
        if model.isChangingListen && model.isListening {
            return String(localized: "detector.listen.stopping", defaultValue: "Stopping…")
        }
        if model.isChangingListen {
            return String(localized: "detector.listen.starting", defaultValue: "Starting…")
        }
        if model.isListening {
            return String(localized: "detector.stop", defaultValue: "Stop")
        }
        return String(localized: "detector.listen", defaultValue: "Listen")
    }

    private var listenSymbol: String {
        model.isListening ? "stop.circle.fill" : "mic.circle.fill"
    }

    private var meters: some View {
        VStack(spacing: 4) {
            InputLevelMeter(level: model.inputLevel)
            ConfidenceMeter(
                confidence: countsFromTaps
                    ? 0
                    : (model.loggedReading?.confidence ?? model.estimate.confidence),
                showsValue: !countsFromTaps
            )
        }
        .padding(.horizontal, 4)
    }

    private var countsFromTaps: Bool {
        model.beatSync?.usedMicrophone == false
    }

    private var tapBeatButton: some View {
        Button {
            model.registerTap()
        } label: {
            Label(
                String(localized: "detector.beat.tap", defaultValue: "Tap the beat"),
                systemImage: "hand.tap.fill"
            )
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier(A11yID.beatTap)
        .accessibilityHint(String(
            localized: "detector.beat.tap.hint",
            defaultValue: "Tap in time with the music. A few taps pick the count and line up the beat."
        ))
    }

    private var countStepButtons: some View {
        HStack(spacing: 8) {
            countStepButton(
                title: String(localized: "detector.count.tooFast", defaultValue: "Too fast"),
                bpm: model.countStep(faster: false),
                faster: false,
                identifier: A11yID.countTooFast
            )
            countStepButton(
                title: String(localized: "detector.count.tooSlow", defaultValue: "Too slow"),
                bpm: model.countStep(faster: true),
                faster: true,
                identifier: A11yID.countTooSlow
            )
        }
    }

    private func countStepButton(title: String, bpm: Int?, faster: Bool, identifier: String) -> some View {
        Button {
            model.stepCount(faster: faster)
        } label: {
            Text(bpm.map { "\(title)\n\($0)" } ?? "\(title)\n ")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.bordered)
        .disabled(bpm == nil)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(bpm.map { "\(title), \($0) beats per minute" } ?? title)
        .accessibilityHint(String(
            localized: "detector.count.hint",
            defaultValue: "Locks this count and retimes the pulse."
        ))
    }

    private var hint: String {
        switch model.beatSyncHint {
        case .keepTapping:
            String(localized: "detector.beat.keepTapping", defaultValue: "Keep tapping with the beat.")
        case .synced:
            String(localized: "detector.beat.synced", defaultValue: "Synced. The pulse follows your taps.")
        case .countedFromTaps:
            String(localized: "detector.beat.counted", defaultValue: "Counted from your taps.")
        case .countLocked:
            String(localized: "detector.beat.countLocked", defaultValue: "Count locked to the pulse.")
        case nil:
            String(
                localized: "detector.count.caption",
                defaultValue: "Too fast if the pulse rushes. Too slow if it drags."
            )
        }
    }

    private func loggedSection(_ reading: TempoReading) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let timestamp = model.loggedTimestampText {
                Text(timestamp)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier(A11yID.loggedTimestamp)
            }
            TempoAlternativesView(alternatives: reading.alternatives)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var scanHistory: some View {
        if !model.scans.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(String(localized: "detector.scans.title", defaultValue: "Previous scans"))
                    .font(.subheadline.weight(.semibold))
                ForEach(Array(model.scans.enumerated()), id: \.element.id) { index, scan in
                    HStack {
                        Text("\(scan.bpm)")
                            .font(.body.weight(.semibold))
                            .monospacedDigit()
                        Text(String(localized: "detector.bpm.unit", defaultValue: "BPM"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(ReadingTimestampFormatter.string(for: scan.loggedAt))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("\(A11yID.scanHistory).\(index)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier(A11yID.scanHistory)
        }
    }

    private var bpmText: String {
        guard let bpm = model.displayedBPM else { return "—" }
        return "\(bpm)"
    }

    private var bpmAccessibilityLabel: String {
        guard let bpm = model.displayedBPM else {
            return String(localized: "detector.bpm.none", defaultValue: "No tempo detected yet")
        }
        if model.beatSync != nil {
            return "\(bpm) beats per minute, synced to your taps"
        }
        return "\(bpm) beats per minute"
    }
}
