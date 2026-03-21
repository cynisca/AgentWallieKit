import SwiftUI

// MARK: - Color Resolution

/// Resolve a color string (hex or theme reference) to a SwiftUI Color.
@available(iOS 16.0, *)
func resolveColor(_ colorString: String?, theme: PaywallTheme?) -> Color? {
    guard let str = colorString, !str.isEmpty else { return nil }

    // Theme references like "{{ theme.primary }}" — strip template syntax
    // Only match actual template syntax (must contain {{ and }})
    if str.contains("{{") && str.contains("theme.") {
        let cleaned = str.replacingOccurrences(of: "{{", with: "")
            .replacingOccurrences(of: "}}", with: "")
            .trimmingCharacters(in: .whitespaces)
        if let theme = theme {
            let themeKey = cleaned.replacingOccurrences(of: "theme.", with: "")
            if let value = theme.value(forKey: themeKey) {
                return Color(hex: value)
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
    let theme: PaywallTheme?
    var skipBackground: Bool = false
    var skipCornerRadius: Bool = false
    var skipHeight: Bool = false

    init(style: ComponentStyle?, theme: PaywallTheme? = nil, skipBackground: Bool = false, skipCornerRadius: Bool = false, skipHeight: Bool = false) {
        self.style = style
        self.theme = theme
        self.skipBackground = skipBackground
        self.skipCornerRadius = skipCornerRadius
        self.skipHeight = skipHeight
    }

    func body(content: Content) -> some View {
        content
            .padding(.top, CGFloat(style?.paddingTop ?? 0))
            .padding(.bottom, CGFloat(style?.paddingBottom ?? 0))
            .padding(.leading, CGFloat(style?.paddingLeft ?? style?.paddingHorizontal ?? 0))
            .padding(.trailing, CGFloat(style?.paddingRight ?? style?.paddingHorizontal ?? 0))
            .padding(.vertical, CGFloat(style?.paddingVertical ?? 0))
            .applyIf(!skipHeight) { view in
                view.applyOptionalFrame(height: style?.height?.doubleValue.map { CGFloat($0) })
            }
            .applyIf(!skipBackground) { view in
                view.applyOptionalBackground(resolveColor(style?.backgroundColor, theme: theme))
            }
            .applyIf(!skipCornerRadius) { view in
                view.applyOptionalCornerRadius(style?.cornerRadius?.doubleValue.map { CGFloat($0) })
            }
            .applyOptionalFrame(width: numericWidth)
            .applyOptionalBorder(
                color: resolveColor(style?.borderColor, theme: theme),
                width: style?.borderWidth,
                cornerRadius: style?.cornerRadius?.doubleValue.map { CGFloat($0) } ?? 0
            )
            .padding(.top, CGFloat(style?.marginTop ?? 0))
            .padding(.bottom, CGFloat(style?.marginBottom ?? 0))
            .padding(.leading, CGFloat(style?.marginLeft ?? style?.marginHorizontal ?? 0))
            .padding(.trailing, CGFloat(style?.marginRight ?? style?.marginHorizontal ?? 0))
            .opacity(style?.opacity ?? 1.0)
            .applyOptionalGlow(resolveColor(style?.glowColor, theme: theme))
    }

    /// Returns numeric width only (ignores percentage strings like "100%")
    private var numericWidth: CGFloat? {
        guard let w = style?.width else { return nil }
        switch w {
        case .number(let n): return CGFloat(n)
        case .string(_): return nil
        case .bool(_): return nil
        }
    }
}

// MARK: - Conditional View Helpers

@available(iOS 16.0, *)
extension View {
    @ViewBuilder
    func applyIf(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyOptionalFrame(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        if let w = width, let h = height {
            self.frame(width: w, height: h)
        } else if let w = width {
            self.frame(width: w)
        } else if let h = height {
            self.frame(height: h)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyOptionalBackground(_ color: Color?) -> some View {
        if let color = color {
            self.background(color)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyOptionalCornerRadius(_ radius: CGFloat?) -> some View {
        if let radius = radius {
            self.cornerRadius(radius)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyOptionalBorder(color: Color?, width: Double?, cornerRadius: CGFloat) -> some View {
        if let color = color, let width = width, width > 0 {
            self.overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: CGFloat(width))
            )
        } else {
            self
        }
    }

    @ViewBuilder
    func applyOptionalGlow(_ color: Color?) -> some View {
        if let color = color {
            self.shadow(color: color, radius: 15, x: 0, y: 4)
        } else {
            self
        }
    }
}
