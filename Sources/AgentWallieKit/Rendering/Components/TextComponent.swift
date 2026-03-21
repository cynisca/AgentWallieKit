import SwiftUI

/// Renders a text component from the paywall schema.
@available(iOS 16.0, *)
struct TextComponentView: View {
    let data: TextComponentData
    let theme: PaywallTheme?
    var resolver: ExpressionResolver?

    var body: some View {
        renderedText
            .font(font(for: data.props.textStyle))
            .multilineTextAlignment(textAlignment(data.props.alignment))
            .frame(maxWidth: .infinity, alignment: frameAlignment(data.props.alignment))
            .foregroundColor(resolveColor(data.style?.color ?? data.style?.textColor, theme: theme) ?? Color(hex: theme?.textPrimary ?? PaywallTheme.defaultTextPrimary))
            .applyOptionalTracking(data.style?.letterSpacing)
            .modifier(StyleModifier(style: data.style, theme: theme))
    }

    @ViewBuilder
    private var renderedText: some View {
        let content = resolvedContent
        if content.contains("**") {
            Text(parseBoldMarkdown(content))
        } else {
            Text(content)
        }
    }

    private var resolvedContent: String {
        guard let resolver = resolver else { return data.props.content }
        return resolver.resolve(data.props.content)
    }

    /// Parse `**text**` patterns into an AttributedString with bold runs.
    private func parseBoldMarkdown(_ text: String) -> AttributedString {
        var result = AttributedString()
        let pattern = try! NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*")
        let nsText = text as NSString
        let matches = pattern.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        var lastEnd = text.startIndex
        for match in matches {
            let fullRange = Range(match.range, in: text)!
            let innerRange = Range(match.range(at: 1), in: text)!

            // Append text before this match
            if lastEnd < fullRange.lowerBound {
                result.append(AttributedString(text[lastEnd..<fullRange.lowerBound]))
            }

            // Append bold text
            var boldPart = AttributedString(text[innerRange])
            boldPart.font = font(for: data.props.textStyle).bold()
            result.append(boldPart)

            lastEnd = fullRange.upperBound
        }

        // Append remaining text
        if lastEnd < text.endIndex {
            result.append(AttributedString(text[lastEnd..<text.endIndex]))
        }

        return result
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

// MARK: - Tracking Extension

@available(iOS 16.0, *)
extension View {
    @ViewBuilder
    func applyOptionalTracking(_ tracking: Double?) -> some View {
        if let tracking = tracking {
            self.tracking(tracking)
        } else {
            self
        }
    }
}
