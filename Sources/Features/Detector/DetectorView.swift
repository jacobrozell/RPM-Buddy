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
                    if let reading = model.loggedReading {
                        loggedSection(reading)
                    }
                    ConfidenceMeter(
                        confidence: model.loggedReading?.confidence ?? model.estimate.confidence,
                        showsValue: true
                    )
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
        return "\(bpm) beats per minute"
    }
}
