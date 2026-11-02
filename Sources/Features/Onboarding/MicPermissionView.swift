import SwiftUI

struct MicPermissionView: View {
    @Bindable var model: DetectorViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text(String(localized: "onboarding.title", defaultValue: "Microphone access"))
                .font(.title.weight(.semibold))
            Text(String(
                localized: "onboarding.body",
                defaultValue: """
                RPM Buddy listens through the microphone to estimate nearby tempo. Audio stays on device.
                """
            ))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Button {
                Task { await model.requestPermission() }
            } label: {
                Text(String(localized: "onboarding.allow", defaultValue: "Allow microphone"))
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier(A11yID.micPermissionButton)
            if model.permission == .denied {
                Text(String(
                    localized: "onboarding.denied",
                    defaultValue: "Microphone access was denied. Enable it in Settings → RPM Buddy."
                ))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
        }
        .padding(24)
    }
}
