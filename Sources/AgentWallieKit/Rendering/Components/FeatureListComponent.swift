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
                        .foregroundColor(resolveColor(data.props.iconColor, theme: theme) ?? .green)
                        .font(.body)
                    Text(item.text)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(StyleModifier(style: data.style))
    }
}
