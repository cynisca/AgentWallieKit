import Foundation

/// Parses simple markdown bold patterns (`**text**`) into `AttributedString`.
@available(iOS 16.0, *)
public enum MarkdownParser {
    private static let boldRegex = try! NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*")

    /// Parse `**bold**` patterns in the input text, returning an `AttributedString`
    /// with `.bold` trait applied to matched segments.
    public static func parse(_ text: String) -> AttributedString {
        guard !text.isEmpty else { return AttributedString() }

        let nsText = text as NSString
        let matches = boldRegex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        guard !matches.isEmpty else {
            return AttributedString(text)
        }

        var result = AttributedString()
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
            boldPart.inlinePresentationIntent = .stronglyEmphasized
            result.append(boldPart)

            lastEnd = fullRange.upperBound
        }

        // Append remaining text
        if lastEnd < text.endIndex {
            result.append(AttributedString(text[lastEnd..<text.endIndex]))
        }

        return result
    }
}
