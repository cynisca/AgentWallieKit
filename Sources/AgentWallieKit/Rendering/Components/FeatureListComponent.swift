import SwiftUI

/// Renders a feature list component from the paywall schema.
@available(iOS 16.0, *)
struct FeatureListComponentView: View {
    let data: FeatureListComponentData
    let theme: PaywallTheme?

    private var rowBackgroundColor: Color? {
        resolveColor(data.style?.backgroundColor, theme: theme)
    }

    private var rowCornerRadius: CGFloat {
        data.style?.cornerRadius?.doubleValue.map { CGFloat($0) } ?? 0
    }

    private var rowPaddingH: CGFloat {
        CGFloat(data.style?.paddingHorizontal ?? data.style?.paddingLeft ?? 12)
    }

    private var rowPaddingV: CGFloat {
        CGFloat(data.style?.paddingVertical ?? data.style?.paddingTop ?? 12)
    }

    private var accentBarColor: Color? {
        resolveColor(data.style?.borderColor, theme: theme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(data.props.items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 12) {
                    if let barColor = accentBarColor {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(barColor)
                            .frame(width: 3)
                    }
                    Image(systemName: item.icon)
                        .foregroundColor(resolveColor(data.props.iconColor, theme: theme) ?? Color(hex: theme?.accent ?? PaywallTheme.defaultAccent))
                        .font(resolveFont(textStyle: "body", fontSize: data.style?.fontSize, fontFamily: data.style?.fontFamily, theme: theme))
                    renderedItemText(item.text)
                        .font(resolveFont(textStyle: "body", fontSize: data.style?.fontSize, fontFamily: data.style?.fontFamily, theme: theme))
                        .foregroundColor(resolveColor(data.style?.color ?? data.style?.textColor, theme: theme) ?? Color(hex: theme?.textPrimary ?? PaywallTheme.defaultTextPrimary))
                }
                .padding(.horizontal, rowPaddingH)
                .padding(.vertical, rowPaddingV)
                .frame(maxWidth: .infinity, alignment: .leading)
                .applyOptionalBackground(rowBackgroundColor)
                .applyOptionalCornerRadius(rowCornerRadius > 0 ? rowCornerRadius : nil)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, CGFloat(data.style?.marginTop ?? 0))
        .padding(.bottom, CGFloat(data.style?.marginBottom ?? 0))
        .padding(.leading, CGFloat(data.style?.marginLeft ?? data.style?.marginHorizontal ?? 0))
        .padding(.trailing, CGFloat(data.style?.marginRight ?? data.style?.marginHorizontal ?? 0))
        .opacity(data.style?.opacity ?? 1.0)
    }

    @ViewBuilder
    private func renderedItemText(_ text: String) -> some View {
        if text.contains("**") {
            Text(parseBoldMarkdown(text))
        } else {
            Text(text)
        }
    }

    private func parseBoldMarkdown(_ text: String) -> AttributedString {
        var result = AttributedString()
        let pattern = try! NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*")
        let nsText = text as NSString
        let matches = pattern.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        let baseFont = resolveFont(textStyle: "body", fontSize: data.style?.fontSize, fontFamily: data.style?.fontFamily, theme: theme)
        var lastEnd = text.startIndex
        for match in matches {
            let fullRange = Range(match.range, in: text)!
            let innerRange = Range(match.range(at: 1), in: text)!
            if lastEnd < fullRange.lowerBound {
                result.append(AttributedString(text[lastEnd..<fullRange.lowerBound]))
            }
            var boldPart = AttributedString(text[innerRange])
            boldPart.font = baseFont.bold()
            result.append(boldPart)
            lastEnd = fullRange.upperBound
        }
        if lastEnd < text.endIndex {
            result.append(AttributedString(text[lastEnd..<text.endIndex]))
        }
        return result
    }
}
