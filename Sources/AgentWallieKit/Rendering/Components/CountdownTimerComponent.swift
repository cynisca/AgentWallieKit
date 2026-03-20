import SwiftUI
import Combine

/// Renders a countdown timer that counts down from a given duration.
@available(iOS 16.0, *)
struct CountdownTimerComponentView: View {
    let data: CountdownTimerComponentData
    let theme: PaywallTheme?

    @State private var remainingSeconds: Int

    init(data: CountdownTimerComponentData, theme: PaywallTheme?) {
        self.data = data
        self.theme = theme
        self._remainingSeconds = State(initialValue: data.props.durationSeconds)
    }

    var body: some View {
        VStack(spacing: 4) {
            if let label = data.props.label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(resolveColor(data.style?.textColor, theme: theme) ?? Color(hex: theme?.textSecondary ?? "#6B7280"))
            }
            Text(formattedTime)
                .font(.system(.title2, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(resolveColor(data.style?.color ?? data.style?.textColor, theme: theme) ?? Color(hex: theme?.textPrimary ?? "#000000"))
        }
        .modifier(StyleModifier(style: data.style, theme: theme))
        .onAppear {
            startTimer()
        }
    }

    private var formattedTime: String {
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                timer.invalidate()
            }
        }
    }
}
