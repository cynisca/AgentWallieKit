import SwiftUI

/// Renders a custom native view registered via CustomViewRegistry, or a placeholder if unregistered.
@available(iOS 16.0, *)
struct CustomViewComponentView: View {
    let data: CustomViewComponentData
    let theme: PaywallTheme?
    let products: [ProductSlot]?
    let userAttributes: [String: AnyCodable]
    let onAction: (TapBehavior, String?) -> Void

    var body: some View {
        Group {
            if let resolvedView = resolveCustomView() {
                resolvedView
            } else {
                placeholderView
            }
        }
        .modifier(StyleModifier(style: data.style, theme: theme))
    }

    private func resolveCustomView() -> AnyView? {
        let context = CustomViewContext(
            viewName: data.props.viewName,
            customData: [:],  // Will be populated when Sprint 1 adds customData to CustomViewProps
            theme: theme,
            products: products,
            userAttributes: userAttributes
        )

        return CustomViewRegistry.shared.resolve(name: data.props.viewName, context: context)
    }

    private var placeholderView: some View {
        VStack(spacing: 4) {
            Image(systemName: "puzzlepiece.extension")
                .font(.title2)
                .foregroundColor(Color(hex: theme?.textSecondary ?? "#6B7280"))
            Text(data.props.viewName)
                .font(.caption)
                .foregroundColor(Color(hex: theme?.textSecondary ?? "#6B7280"))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: theme?.textSecondary ?? "#6B7280").opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
        )
    }
}
