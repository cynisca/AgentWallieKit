import SwiftUI

/// Renders a horizontal divider with configurable color and thickness.
@available(iOS 16.0, *)
struct DividerComponentView: View {
    let data: DividerComponentData
    let theme: PaywallTheme?

    var body: some View {
        Rectangle()
            .fill(resolveColor(data.props?.color, theme: theme) ?? Color.gray.opacity(0.3))
            .frame(height: CGFloat(data.props?.thickness ?? 1))
            .frame(maxWidth: .infinity)
            .modifier(StyleModifier(style: data.style, theme: theme, skipHeight: true))
    }
}
