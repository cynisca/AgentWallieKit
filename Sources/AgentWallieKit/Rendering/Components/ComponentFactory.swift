import SwiftUI

// MARK: - Color Resolution

/// Resolve a color string (hex or theme reference) to a SwiftUI Color.
@available(iOS 16.0, *)
func resolveColor(_ colorString: String?, theme: PaywallTheme?) -> Color? {
    guard let str = colorString, !str.isEmpty else { return nil }

    // Theme references like "{{ theme.primary }}" — strip template syntax
    if str.contains("theme.") {
        let cleaned = str.replacingOccurrences(of: "{{", with: "")
            .replacingOccurrences(of: "}}", with: "")
            .trimmingCharacters(in: .whitespaces)
        if let theme = theme {
            switch cleaned {
            case "theme.primary": return Color(hex: theme.primary)
            case "theme.secondary": return Color(hex: theme.secondary)
            case "theme.background": return Color(hex: theme.background)
            case "theme.text_primary": return Color(hex: theme.textPrimary)
            case "theme.text_secondary": return Color(hex: theme.textSecondary)
            case "theme.accent": return Color(hex: theme.accent)
            case "theme.surface": return Color(hex: theme.surface)
            default: break
            }
        }
        return nil
    }

    return Color(hex: str)
}

/// Parse text alignment string.
func textAlignment(_ alignment: String?) -> TextAlignment {
    switch alignment {
    case "center": return .center
    case "trailing", "right": return .trailing
    case "leading", "left": return .leading
    default: return .leading
    }
}

/// Parse frame alignment string.
func frameAlignment(_ alignment: String?) -> Alignment {
    switch alignment {
    case "center": return .center
    case "trailing", "right": return .trailing
    case "leading", "left": return .leading
    default: return .leading
    }
}

// MARK: - Hex Color Extension

@available(iOS 16.0, *)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Style Modifier

/// Applies ComponentStyle properties as SwiftUI modifiers.
@available(iOS 16.0, *)
struct StyleModifier: ViewModifier {
    let style: ComponentStyle?
    var skipBackground: Bool = false
    var skipCornerRadius: Bool = false
    var skipHeight: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(.top, CGFloat(style?.marginTop ?? style?.paddingTop ?? 0))
            .padding(.bottom, CGFloat(style?.marginBottom ?? style?.paddingBottom ?? 0))
            .padding(.horizontal, CGFloat(style?.marginHorizontal ?? style?.paddingHorizontal ?? 0))
            .opacity(style?.opacity ?? 1.0)
    }
}
