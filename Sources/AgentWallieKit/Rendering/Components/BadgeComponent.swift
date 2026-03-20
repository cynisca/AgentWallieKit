import SwiftUI

/// Renders a pill-shaped badge label with filled, outlined, or soft variants.
@available(iOS 16.0, *)
struct BadgeComponentView: View {
    let data: BadgeComponentData
    let theme: PaywallTheme?

    private var variant: String {
        data.props.variant ?? "filled"
    }

    private var themeColor: Color {
        resolveColor(data.style?.color ?? data.style?.textColor, theme: theme)
            ?? Color(hex: theme?.primary ?? PaywallTheme.defaultPrimary)
    }

    var body: some View {
        Text(data.props.text)
            .font(.system(size: data.style?.fontSize ?? 12, weight: .semibold))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: pillRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: pillRadius))
            .modifier(StyleModifier(
                style: data.style,
                theme: theme,
                skipBackground: true,
                skipCornerRadius: true
            ))
    }

    private var pillRadius: CGFloat {
        data.style?.cornerRadius?.doubleValue.map { CGFloat($0) } ?? 999
    }

    private var foregroundColor: Color {
        switch variant {
        case "filled":
            return .white
        case "outlined", "soft":
            return themeColor
        default:
            return .white
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case "filled":
            return themeColor
        case "outlined":
            return .clear
        case "soft":
            return themeColor.opacity(0.15)
        default:
            return themeColor
        }
    }

    private var borderColor: Color {
        switch variant {
        case "outlined":
            return themeColor
        default:
            return .clear
        }
    }

    private var borderWidth: CGFloat {
        switch variant {
        case "outlined":
            return 1.5
        default:
            return 0
        }
    }
}
