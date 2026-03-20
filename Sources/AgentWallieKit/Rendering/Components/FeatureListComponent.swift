import SwiftUI

/// Renders a feature list component from the paywall schema.
@available(iOS 16.0, *)
struct FeatureListComponentView: View {
    let data: FeatureListComponentData
    let theme: PaywallTheme?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(data.props.items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 12) {
                    Image(systemName: item.icon)
                        .foregroundColor(resolveColor(data.props.iconColor, theme: theme) ?? Color(hex: theme?.accent ?? "#34C759"))
                        .font(.body)
                    Text(item.text)
                        .font(.body)
                        .foregroundColor(resolveColor(data.style?.color ?? data.style?.textColor, theme: theme) ?? Color(hex: theme?.textPrimary ?? "#000000"))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(StyleModifier(style: data.style, theme: theme))
    }
}
