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

    private var effectiveHeight: CGFloat {
        let baseHeight = data.style?.height?.doubleValue.map { CGFloat($0) } ?? 56
        let verticalPadding = CGFloat(data.style?.paddingVertical ?? 0)
        return baseHeight + verticalPadding * 2
    }

    private var bgColor: Color {
        resolveColor(data.style?.backgroundColor, theme: theme) ?? Color(hex: theme?.primary ?? PaywallTheme.defaultPrimary)
    }

    private var fgColor: Color {
        resolveColor(data.style?.textColor ?? data.style?.color, theme: theme) ?? .white
    }

    var body: some View {
        Button {
            onAction(data.props.action, resolveActionParam(for: data.props))
        } label: {
            VStack(spacing: 2) {
                Text(resolvedText)
                    .font(resolveFont(textStyle: "headline", fontSize: data.style?.fontSize, fontFamily: data.style?.fontFamily, theme: theme))
                    .foregroundColor(fgColor)
                if let subtitle = resolvedSubtitle {
                    Text(subtitle)
                        .font(resolveFont(textStyle: "footnote", fontSize: nil, fontFamily: data.style?.fontFamily, theme: theme))
                        .foregroundColor(fgColor.opacity(0.75))
                }
            }
            .frame(maxWidth: .infinity, minHeight: effectiveHeight)
        }
        .background(buttonBackground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .modifier(StyleModifier(style: data.style, theme: theme, skipBackground: true, skipCornerRadius: true, skipHeight: true, skipPaddingVertical: true))
    }

    @ViewBuilder
    private var buttonBackground: some View {
        if let gradient = data.style?.backgroundGradient, !gradient.colors.isEmpty {
            GradientBackground(gradient: gradient, theme: theme)
        } else {
            bgColor
        }
    }

    private var cornerRadius: CGFloat {
        if let cr = data.style?.cornerRadius?.doubleValue {
            return CGFloat(cr)
        }
        return CGFloat(theme?.cornerRadius ?? 12)
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
