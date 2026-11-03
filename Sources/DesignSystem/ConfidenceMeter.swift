import SwiftUI

struct ConfidenceMeter: View {
    let confidence: Double
    let showsValue: Bool

    private var label: String {
        let percent = Int((confidence * 100).rounded())
        if confidence < 0.15 {
            return String(localized: "confidence.low", defaultValue: "Low confidence")
        }
        if confidence < 0.45 {
            return String(localized: "confidence.moderate", defaultValue: "Moderate confidence")
        }
        return String(localized: "confidence.high", defaultValue: "High confidence")
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(String(localized: "confidence.title", defaultValue: "Confidence"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)
            Gauge(value: confidence, in: 0...1) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .tint(showsValue ? confidenceTint : .secondary)
            Text(valueText)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .trailing)
        }
        .frame(height: 32)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(showsValue ? label : String(localized: "confidence.fromTaps", defaultValue: "Taps"))
        .accessibilityValue(showsValue ? "\(Int((confidence * 100).rounded())) percent" : "")
        .accessibilityIdentifier(A11yID.confidenceMeter)
    }

    private var valueText: String {
        if showsValue {
            return "\(Int((confidence * 100).rounded()))%"
        }
        return String(localized: "confidence.fromTaps", defaultValue: "Taps")
    }

    private var confidenceTint: Color {
        if confidence < 0.15 { return .orange }
        if confidence < 0.45 { return .yellow }
        return .green
    }
}
