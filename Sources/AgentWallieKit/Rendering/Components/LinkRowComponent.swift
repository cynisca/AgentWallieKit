import SwiftUI

/// Renders a link row component from the paywall schema.
@available(iOS 16.0, *)
struct LinkRowComponentView: View {
    let data: LinkRowComponentData
    let theme: PaywallTheme?
    let onAction: (TapBehavior, String?) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(data.props.links.enumerated()), id: \.offset) { index, link in
                if index > 0, let separator = data.props.separator {
                    Text(separator)
                        .font(.system(size: fontSize))
                        .foregroundColor(textColor)
                }

                Button(action: {
                    if link.action == .openUrl {
                        onAction(.openUrl, link.url)
                    } else {
                        onAction(link.action, nil)
                    }
                }) {
                    Text(link.text)
                        .font(.system(size: fontSize))
                        .foregroundColor(textColor)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .modifier(StyleModifier(style: data.style))
    }

    private var fontSize: CGFloat {
        CGFloat(data.style?.fontSize ?? 12)
    }

    private var textColor: Color {
        resolveColor(data.style?.textColor ?? data.style?.color, theme: theme) ?? .secondary
    }
}
