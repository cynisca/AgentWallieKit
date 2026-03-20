import SwiftUI

/// Renders a CTA button component from the paywall schema.
@available(iOS 16.0, *)
struct CTAButtonComponentView: View {
    let data: CTAButtonComponentData
    let theme: PaywallTheme?
    let onAction: (TapBehavior, String?) -> Void
    var resolver: ExpressionResolver?

    private var resolvedText: String {
        guard let resolver = resolver else { return data.props.text }
        return resolver.resolve(data.props.text)
    }

    private var resolvedSubtitle: String? {
        guard let subtitle = data.props.subtitle else { return nil }
        guard let resolver = resolver else { return subtitle }
        return resolver.resolve(subtitle)
    }

    var body: some View {
        Button(action: { onAction(data.props.action, data.props.product) }) {
            VStack(spacing: 4) {
                Text(resolvedText)
                    .font(.headline)
                    .foregroundColor(resolveColor(data.style?.textColor, theme: theme) ?? .white)

                if let subtitle = resolvedSubtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor((resolveColor(data.style?.textColor, theme: theme) ?? .white).opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: data.style?.height?.doubleValue.map { CGFloat($0) } ?? 56)
            .background(resolveColor(data.style?.backgroundColor, theme: theme) ?? Color(hex: theme?.primary ?? PaywallTheme.defaultPrimary))
            .cornerRadius(cornerRadius)
        }
        .modifier(StyleModifier(style: data.style, theme: theme, skipBackground: true, skipCornerRadius: true, skipHeight: true))
    }

    private var cornerRadius: CGFloat {
        if let cr = data.style?.cornerRadius?.doubleValue {
            return CGFloat(cr)
        }
        return CGFloat(theme?.cornerRadius ?? 12)
    }
}
