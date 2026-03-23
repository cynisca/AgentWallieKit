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

    /// Effective height: explicit style height, or default 56pt, plus any padding_vertical
    private var effectiveHeight: CGFloat {
        let baseHeight = data.style?.height?.doubleValue.map { CGFloat($0) } ?? 56
        let verticalPadding = CGFloat(data.style?.paddingVertical ?? 0)
        return baseHeight + verticalPadding * 2
    }

    var body: some View {
        Button(action: {
            onAction(data.props.action, resolveActionParam(for: data.props))
        }) {
            VStack(spacing: 4) {
                Text(resolvedText)
                    .font(resolveFont(textStyle: "headline", fontSize: data.style?.fontSize, fontFamily: data.style?.fontFamily, theme: theme))
                    .foregroundColor(resolveColor(data.style?.textColor ?? data.style?.color, theme: theme) ?? .white)

                if let subtitle = resolvedSubtitle {
                    Text(subtitle)
                        .font(resolveFont(textStyle: "subheadline", fontSize: nil, fontFamily: data.style?.fontFamily, theme: theme))
                        .foregroundColor((resolveColor(data.style?.textColor ?? data.style?.color, theme: theme) ?? .white).opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: effectiveHeight)
            .background(resolveColor(data.style?.backgroundColor, theme: theme) ?? Color(hex: theme?.primary ?? PaywallTheme.defaultPrimary))
            .cornerRadius(cornerRadius)
            .contentShape(Rectangle())
        }
        .buttonStyle(CTAButtonStyle())
        .modifier(StyleModifier(style: data.style, theme: theme, skipBackground: true, skipCornerRadius: true, skipHeight: true, skipPaddingVertical: true))
    }

    private var cornerRadius: CGFloat {
        if let cr = data.style?.cornerRadius?.doubleValue {
            return CGFloat(cr)
        }
        return CGFloat(theme?.cornerRadius ?? 12)
    }
}

/// Plain button style that preserves tap handling in ScrollView
@available(iOS 16.0, *)
struct CTAButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

/// Resolves the parameter to pass to `onAction` based on the button's action type.
func resolveActionParam(for props: CTAButtonComponentData.CTAButtonProps) -> String? {
    switch props.action {
    case .purchase, .selectProduct:
        return props.product ?? "selected"
    case .customAction:
        return props.actionName
    case .customPlacement:
        return props.placementName
    case .openUrl:
        return props.url
    default:
        return nil
    }
}
