import SwiftUI

/// Renders a star rating display with value, star icons, count, and optional label.
@available(iOS 16.0, *)
struct RatingComponentView: View {
    let data: RatingComponentData
    let theme: PaywallTheme?

    private var maxStars: Int {
        data.props.maxStars ?? 5
    }

    private var accentColor: Color {
        resolveColor(data.style?.color, theme: theme)
            ?? Color(hex: theme?.accent ?? "#FF9500")
    }

    private var textColor: Color {
        resolveColor(data.style?.textColor, theme: theme)
            ?? Color(hex: theme?.textPrimary ?? PaywallTheme.defaultTextPrimary)
    }

    private var ratingFontSize: CGFloat {
        data.style?.fontSize.map { CGFloat($0) } ?? 16
    }

    var body: some View {
        HStack(spacing: 4) {
            // Numeric value
            Text(formatValue(data.props.value))
                .font(resolveFont(textStyle: "callout", fontSize: data.style?.fontSize, fontFamily: data.style?.fontFamily, theme: theme))
                .fontWeight(.bold)
                .foregroundColor(textColor)

            // Star icons
            HStack(spacing: 1) {
                ForEach(0..<maxStars, id: \.self) { index in
                    starImage(for: index)
                        .font(.system(size: ratingFontSize * 0.85))
                        .foregroundColor(accentColor)
                }
            }

            // Count
            if let count = data.props.count {
                Text("(\(formatCount(count)))")
                    .font(resolveFont(textStyle: "caption", fontSize: (data.style?.fontSize).map { $0 * 0.85 }, fontFamily: data.style?.fontFamily, theme: theme))
                    .foregroundColor(Color(hex: theme?.textSecondary ?? PaywallTheme.defaultTextSecondary))
            }

            // Label
            if let label = data.props.label {
                Text(label)
                    .font(resolveFont(textStyle: "caption", fontSize: (data.style?.fontSize).map { $0 * 0.85 }, fontFamily: data.style?.fontFamily, theme: theme))
                    .foregroundColor(Color(hex: theme?.textSecondary ?? PaywallTheme.defaultTextSecondary))
            }
        }
        .modifier(StyleModifier(style: data.style, theme: theme))
    }

    @ViewBuilder
    private func starImage(for index: Int) -> some View {
        let value = data.props.value
        let floored = Int(value)
        let fraction = value - Double(floored)

        if index < floored {
            Image(systemName: "star.fill")
        } else if index == floored && fraction >= 0.25 {
            Image(systemName: "star.leadinghalf.filled")
        } else {
            Image(systemName: "star")
        }
    }

    private func formatValue(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            let millions = Double(count) / 1_000_000.0
            return String(format: "%.1fM", millions)
        } else if count >= 1_000 {
            let thousands = Double(count) / 1_000.0
            return String(format: "%.1fK", thousands)
        }
        return "\(count)"
    }
}
