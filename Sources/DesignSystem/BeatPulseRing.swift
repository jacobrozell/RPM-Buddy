import SwiftUI

/// Flashes on the downbeat anchored to the user's last tap.
struct BeatPulseRing: View {
    let bpm: Int
    let anchor: Date
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion || LaunchConfiguration.mockBPM != nil {
                ring(flash: 0.35)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    ring(flash: flash(at: timeline.date))
                }
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func ring(flash: Double) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .strokeBorder(Color.accentColor.opacity(0.25 + 0.75 * flash), lineWidth: 2 + 4 * flash)
            .padding(1)
    }

    private func flash(at date: Date) -> Double {
        let period = 60.0 / Double(max(bpm, 1))
        let elapsed = date.timeIntervalSince(anchor)
        let phase = elapsed.truncatingRemainder(dividingBy: period) / period
        let wrapped = phase < 0 ? phase + 1 : phase
        return max(0, 1 - wrapped * 5)
    }
}
