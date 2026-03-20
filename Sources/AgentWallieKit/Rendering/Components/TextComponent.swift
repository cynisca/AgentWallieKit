import SwiftUI

/// Renders a text component from the paywall schema.
@available(iOS 16.0, *)
struct TextComponentView: View {
    let data: TextComponentData
    let theme: PaywallTheme?

    var body: some View {
        Text(data.props.content)
            .font(font(for: data.props.textStyle))
            .multilineTextAlignment(textAlignment(data.props.alignment))
            .frame(maxWidth: .infinity, alignment: frameAlignment(data.props.alignment))
            .foregroundColor(resolveColor(data.style?.color ?? data.style?.textColor, theme: theme) ?? Color(hex: theme?.textPrimary ?? "#000000"))
            .modifier(StyleModifier(style: data.style, theme: theme))
    }

    private func font(for textStyle: String?) -> Font {
        switch textStyle {
        case "largeTitle": return .largeTitle
        case "title1": return .title
        case "title2": return .title2
        case "title3": return .title3
        case "headline": return .headline
        case "subheadline": return .subheadline
        case "body": return .body
        case "callout": return .callout
        case "footnote": return .footnote
        case "caption": return .caption
        case "caption2": return .caption2
        default: return .body
        }
    }
}
