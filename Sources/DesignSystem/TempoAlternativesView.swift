import SwiftUI

struct TempoAlternativesView: View {
    let alternatives: [TempoAlternative]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "tempo.alternatives.title", defaultValue: "Same pulse"))
                .font(.subheadline.weight(.semibold))
            FlowLayout(spacing: 8) {
                ForEach(alternatives) { alternative in
                    alternativeChip(alternative)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(A11yID.tempoAlternatives)
    }

    @ViewBuilder
    private func alternativeChip(_ alternative: TempoAlternative) -> some View {
        let label = "\(alternative.bpm) BPM · \(alternative.feel.label)"
        Text(label)
            .font(.subheadline.weight(alternative.isPrimary ? .semibold : .regular))
            .monospacedDigit()
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(chipBackground(alternative.isPrimary), in: Capsule())
            .overlay {
                if alternative.isPrimary {
                    Capsule().strokeBorder(Color.accentColor, lineWidth: 1.5)
                }
            }
            .accessibilityLabel(label)
            .accessibilityAddTraits(alternative.isPrimary ? .isSelected : [])
            .accessibilityIdentifier("\(A11yID.tempoAlternativePrefix).\(alternative.bpm)")
    }

    private func chipBackground(_ isPrimary: Bool) -> some ShapeStyle {
        isPrimary ? AnyShapeStyle(Color.accentColor.opacity(0.15)) : AnyShapeStyle(.thinMaterial)
    }
}

/// Simple wrapping horizontal layout for tempo chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        if width < 1 {
            let height = subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            return CGSize(width: 0, height: height)
        }
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}
