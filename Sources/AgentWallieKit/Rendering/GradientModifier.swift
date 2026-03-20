import SwiftUI

// MARK: - Gradient Direction Constants

/// Known gradient direction string values matching the JSON schema.
enum GradientDirectionValue {
    static let vertical = "vertical"
    static let horizontal = "horizontal"
    static let diagonalDown = "diagonal_down"
    static let diagonalUp = "diagonal_up"
}

// MARK: - Gradient Background

/// A SwiftUI View that renders a LinearGradient from a BackgroundGradient schema object.
///
/// Colors are resolved through `resolveColor()` to support both hex values and
/// theme references (e.g., `{{ theme.primary }}`).
@available(iOS 16.0, *)
struct GradientBackground: View {
    let gradient: BackgroundGradient
    let theme: PaywallTheme?

    var body: some View {
        if resolvedColors.isEmpty {
            Color.clear
        } else if resolvedColors.count == 1 {
            resolvedColors[0]
        } else {
            LinearGradient(
                colors: resolvedColors,
                startPoint: startPoint,
                endPoint: endPoint
            )
        }
    }

    // MARK: - Color Resolution

    var resolvedColors: [Color] {
        gradient.colors.compactMap { colorString in
            resolveColor(colorString, theme: theme)
        }
    }

    // MARK: - Direction Mapping

    var startPoint: UnitPoint {
        switch gradient.direction ?? GradientDirectionValue.vertical {
        case GradientDirectionValue.horizontal:
            return .leading
        case GradientDirectionValue.diagonalDown:
            return .topLeading
        case GradientDirectionValue.diagonalUp:
            return .bottomLeading
        default:
            return .top
        }
    }

    var endPoint: UnitPoint {
        switch gradient.direction ?? GradientDirectionValue.vertical {
        case GradientDirectionValue.horizontal:
            return .trailing
        case GradientDirectionValue.diagonalDown:
            return .bottomTrailing
        case GradientDirectionValue.diagonalUp:
            return .topTrailing
        default:
            return .bottom
        }
    }
}

// MARK: - View Extension

@available(iOS 16.0, *)
extension View {
    /// Apply a gradient background if the gradient is non-nil.
    @ViewBuilder
    func applyGradientBackground(_ gradient: BackgroundGradient?, theme: PaywallTheme?) -> some View {
        if let gradient = gradient, !gradient.colors.isEmpty {
            self.background(GradientBackground(gradient: gradient, theme: theme))
        } else {
            self
        }
    }
}
