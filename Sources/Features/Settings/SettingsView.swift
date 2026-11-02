import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selfTestResults: [MetronomeSelfTestResult] = []
    @State private var isRunningSelfTest = false

    var body: some View {
        NavigationStack {
            Form {
                verificationSection
                Section(String(localized: "settings.about", defaultValue: "About")) {
                    LabeledContent(String(localized: "settings.version", defaultValue: "Version"), value: appVersion)
                }
                Section(String(localized: "settings.links", defaultValue: "Links")) {
                    Link(String(localized: "settings.support", defaultValue: "Support"), destination: AppLinks.support)
                    Link(
                        String(localized: "settings.privacy", defaultValue: "Privacy Policy"),
                        destination: AppLinks.privacy
                    )
                    Link(
                        String(localized: "settings.accessibility", defaultValue: "Accessibility"),
                        destination: AppLinks.accessibility
                    )
                }
                Section {
                    Text(String(
                        localized: "settings.disclaimer",
                        defaultValue: """
                        RPM Buddy provides tempo estimates, not metronome-grade measurements. \
                        Confidence reflects analysis quality, not musical correctness.
                        """
                    ))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(String(localized: "settings.title", defaultValue: "Settings"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "settings.done", defaultValue: "Done")) { dismiss() }
                }
            }
        }
    }

    private var verificationSection: some View {
        Section {
            Button {
                runSelfTests()
            } label: {
                HStack {
                    Text(String(localized: "settings.verify.metronome", defaultValue: "Run metronome verification"))
                    Spacer()
                    if isRunningSelfTest {
                        ProgressView()
                    }
                }
            }
            .disabled(isRunningSelfTest)
            .accessibilityIdentifier(A11yID.metronomeSelfTest)

            if !selfTestResults.isEmpty {
                ForEach(selfTestResults, id: \.fixture.id) { result in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.fixture.displayName)
                            .font(.subheadline.weight(.semibold))
                        Text(result.summary)
                            .font(.footnote)
                            .foregroundStyle(result.passed ? .green : .orange)
                    }
                    .accessibilityIdentifier("\(A11yID.metronomeSelfTestResult).\(result.fixture.id)")
                }
            }

            Text(String(
                localized: "settings.verify.caption",
                defaultValue: """
                Analyzes bundled metronome WAVs (same pipeline as the mic). Use before device speaker tests.
                """
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
        } header: {
            Text(String(localized: "settings.verify.header", defaultValue: "Verification"))
        }
    }

    private func runSelfTests() {
        isRunningSelfTest = true
        selfTestResults = MetronomeFixtureCatalog.generated.map { MetronomeSelfTest.run(fixture: $0) }
        isRunningSelfTest = false
        let failedCount = selfTestResults.filter { !$0.passed }.count
        AppLogging.logger.info(
            .settings,
            eventName: "metronome_self_test_completed",
            message: "Metronome self-test finished.",
            metadata: [
                "status": failedCount == 0 ? "passed" : "failed",
                "passedCount": String(selfTestResults.count - failedCount),
                "failedCount": String(failedCount)
            ]
        )
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
