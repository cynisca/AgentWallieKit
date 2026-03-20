import SwiftUI

/// Renders a VStack or HStack based on direction, recursively rendering children.
@available(iOS 16.0, *)
struct StackComponentView: View {
    let data: StackComponentData
    let theme: PaywallTheme?
    let onAction: (TapBehavior, String?) -> Void
    let renderComponent: (PaywallComponent) -> AnyView

    var body: some View {
        let spacing = data.props.spacing.map { CGFloat($0) } ?? 0

        Group {
            if data.props.direction == "horizontal" {
                HStack(spacing: spacing) {
                    ForEach(Array(data.children.enumerated()), id: \.offset) { _, child in
                        renderComponent(child)
                    }
                }
            } else {
                VStack(spacing: spacing) {
                    ForEach(Array(data.children.enumerated()), id: \.offset) { _, child in
                        renderComponent(child)
                    }
                }
            }
        }
        .modifier(StyleModifier(style: data.style, theme: theme))
    }
}
