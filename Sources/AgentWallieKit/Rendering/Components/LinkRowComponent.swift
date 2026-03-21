import SwiftUI

/// Renders a link row component from the paywall schema.
@available(iOS 16.0, *)
struct LinkRowComponentView: View {
    let data: LinkRowComponentData
    let theme: PaywallTheme?
    let onAction: (TapBehavior, String?) -> Void

    private var linkFont: Font {
        resolveFont(textStyle: "caption", fontSize: data.style?.fontSize, fontFamily: data.style?.fontFamily, theme: theme)
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(data.props.links.enumerated()), id: \.offset) { index, link in
                if index > 0, let separator = data.props.separator {
                    Text(separator)
                        .font(linkFont)
                        .foregroundColor(separatorColor)
                }

                Button(action: {
                    if link.action == .openUrl {
                        onAction(.openUrl, link.url)
                    } else {
                        onAction(link.action, nil)
                    }
                }) {
                    Text(link.text)
                        .font(linkFont)
                        .foregroundColor(textColor)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .modifier(StyleModifier(style: data.style, theme: theme))
    }

    private var textColor: Color {
        resolveColor(data.style?.textColor ?? data.style?.color, theme: theme)
            ?? Color(hex: theme?.textSecondary ?? PaywallTheme.defaultTextSecondary)
    }

    private var separatorColor: Color {
        Color(hex: theme?.textSecondary ?? PaywallTheme.defaultTextSecondary).opacity(0.5)
    }
}
