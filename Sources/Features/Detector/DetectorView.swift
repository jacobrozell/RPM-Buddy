import SwiftUI

struct DetectorView: View {
    @Bindable var model: DetectorViewModel
    @State private var showsSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    bpmCard
                    countStepButtons
                    tapBeatButton
                    if let reading = model.loggedReading {
                        loggedSection(reading)
                    }
                    if model.beatSync?.usedMicrophone != false {
                        ConfidenceMeter(
                            confidence: model.loggedReading?.confidence ?? model.estimate.confidence,
                            showsValue: true
                        )
                    }
                    InputLevelMeter(level: model.inputLevel)
                    listenButton
                    Text(model.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "detector.subtitle", defaultValue: "Tempo from the mic"))
                .font(.title2.weight(.semibold))
            Text(String(
                localized: "detector.instructions",
                defaultValue: """
                Point your phone at a speaker or record. RPM Buddy estimates beats per minute from the mic.
                """
            ))
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var bpmCard: some View {
        VStack(spacing: 8) {
            Text(bpmText)
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(bpmAccessibilityLabel)
                .accessibilityIdentifier(A11yID.bpmValue)
            Text(String(localized: "detector.bpm.unit", defaultValue: "BPM"))
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            if let feltBeat = model.feltBeat {
                BeatPulseRing(bpm: feltBeat.bpm, anchor: feltBeat.anchor)
            }
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: model.beatTick)
    }

    @ViewBuilder
    private var countStepButtons: some View {
        if model.displayedBPM != nil,
           model.countStep(faster: false) != nil || model.countStep(faster: true) != nil {
            VStack(alignment: .leading, spacing: 8) {
                if let slower = model.countStep(faster: false) {
                    countStepButton(
                        title: String(localized: "detector.count.tooFast", defaultValue: "Too fast"),
                        bpm: slower,
                        faster: false,
                        identifier: A11yID.countTooFast
                    )
                }
                if let quicker = model.countStep(faster: true) {
                    countStepButton(
                        title: String(localized: "detector.count.tooSlow", defaultValue: "Too slow"),
                        bpm: quicker,
                        faster: true,
                        identifier: A11yID.countTooSlow
                    )
                }
                Text(String(
                    localized: "detector.count.caption",
                    defaultValue: "If the pulse feels rushed, choose Too fast. If it drags, choose Too slow."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func countStepButton(title: String, bpm: Int, faster: Bool, identifier: String) -> some View {
        Button {
            model.stepCount(faster: faster)
        } label: {
            Text("\(title) · \(bpm)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel("\(title), \(bpm) beats per minute")
        .accessibilityHint(String(
            localized: "detector.count.hint",
            defaultValue: "Locks this count and retimes the pulse."
        ))
    }

    private var tapBeatButton: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                model.registerTap()
            } label: {
                Label(
                    String(localized: "detector.beat.tap", defaultValue: "Tap the beat"),
                    systemImage: "hand.tap.fill"
                )
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 64)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier(A11yID.beatTap)
            .accessibilityHint(String(
                localized: "detector.beat.tap.hint",
                defaultValue: "Tap in time with the music. A few taps pick the count and line up the beat."
            ))
            .sensoryFeedback(.impact, trigger: model.acceptedTapCount)
            Text(beatSyncCaption)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier(A11yID.beatSyncHint)
        }
    }

    private var beatSyncCaption: String {
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
                localized: "detector.beat.caption",
                defaultValue: "While listening, tap in time with the song. A few taps pick the count and line up the beat."
            )
        }
    }

    @ViewBuilder
    private func loggedSection(_ reading: TempoReading) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "detector.logged.title", defaultValue: "Logged reading"))
                    .font(.subheadline.weight(.semibold))
                if let timestamp = model.loggedTimestampText {
                    Text(timestamp)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier(A11yID.loggedTimestamp)
                }
            }
            TempoAlternativesView(alternatives: reading.alternatives)
        }
    }

    private var listenButton: some View {
        Button {
            Task { await model.toggleListening() }
        } label: {
            Label(
                model.isListening
                    ? String(localized: "detector.stop", defaultValue: "Stop")
                    : String(localized: "detector.listen", defaultValue: "Listen"),
                systemImage: model.isListening ? "stop.circle.fill" : "mic.circle.fill"
            )
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier(A11yID.listenToggle)
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
