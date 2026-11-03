import SwiftUI

struct InputLevelMeter: View {
    let level: Float

    var body: some View {
        HStack(spacing: 12) {
            Text(String(localized: "input.title", defaultValue: "Mic"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: max(8, proxy.size.width * CGFloat(level)))
                }
            }
            .frame(height: 10)
        }
        .frame(height: 32)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "input.a11y", defaultValue: "Microphone input level"))
        .accessibilityValue("\(Int((level * 100).rounded())) percent")
        .accessibilityIdentifier(A11yID.inputLevel)
    }
}
