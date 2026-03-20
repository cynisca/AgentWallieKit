import SwiftUI

/// Renders a spacer component with configurable height.
@available(iOS 16.0, *)
struct SpacerComponentView: View {
    let data: SpacerComponentData
    let theme: PaywallTheme?

    var body: some View {
        Spacer()
            .frame(height: data.style?.height?.doubleValue.map { CGFloat($0) } ?? 16)
            .modifier(StyleModifier(style: data.style, theme: theme, skipHeight: true))
    }
}
