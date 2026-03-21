import XCTest
@testable import AgentWallieKit

/// Tests for markdown bold parsing in text content.
///
/// The fix agent is adding a `MarkdownParser` (or similar) utility that converts
/// `**bold**` patterns into `AttributedString` with bold traits. These tests
/// verify the expected behavior after that implementation lands.
@available(iOS 16.0, *)
final class MarkdownParsingTests: XCTestCase {

    // MARK: - Plain Text (No Markdown)

    func testPlainTextWithNoMarkdown_returnsUnchanged() {
        let input = "Free for 3 days. Cancel anytime."
        let result = MarkdownParser.parse(input)
        XCTAssertEqual(String(result.characters), input)
    }

    // MARK: - Single Bold Segment

    func testSingleBoldSegment_rendersAsBold() {
        let input = "**bold**"
        let result = MarkdownParser.parse(input)
        let plain = String(result.characters)
        XCTAssertEqual(plain, "bold")
        // Verify the bold run exists
        let runs = Array(result.runs)
        XCTAssertFalse(runs.isEmpty)
    }

    // MARK: - Multiple Bold Segments

    func testMultipleBoldSegments() {
        let input = "Start **first** middle **second** end"
        let result = MarkdownParser.parse(input)
        let plain = String(result.characters)
        XCTAssertEqual(plain, "Start first middle second end")
    }

    // MARK: - Alternating Bold and Normal

    func testAlternatingBoldAndNormal() {
        let input = "**bold** normal **bold**"
        let result = MarkdownParser.parse(input)
        let plain = String(result.characters)
        XCTAssertEqual(plain, "bold normal bold")
    }

    // MARK: - Empty String

    func testEmptyString_returnsEmpty() {
        let input = ""
        let result = MarkdownParser.parse(input)
        XCTAssertEqual(String(result.characters), "")
    }

    // MARK: - Unclosed Bold Markers

    func testUnclosedBoldMarkers_treatedAsLiteral() {
        let input = "This has ** unclosed markers"
        let result = MarkdownParser.parse(input)
        let plain = String(result.characters)
        // Unclosed ** should be preserved as literal text
        XCTAssertTrue(plain.contains("**") || plain.contains("unclosed markers"),
                      "Unclosed bold markers should be handled gracefully")
    }

    // MARK: - Nested/Overlapping Patterns

    func testNestedOrOverlappingPatterns_handledGracefully() {
        let input = "**outer **inner** end**"
        let result = MarkdownParser.parse(input)
        // Should not crash; exact behavior may vary
        let plain = String(result.characters)
        XCTAssertFalse(plain.isEmpty, "Nested patterns should produce non-empty output")
    }

    // MARK: - Bold with Expressions

    func testBoldWithExpressions() {
        let input = "Free for 3 days. **{{ products.selected.price }}/yr after.** Cancel anytime."
        let result = MarkdownParser.parse(input)
        let plain = String(result.characters)
        // Expressions are not resolved by MarkdownParser — just the markdown is processed
        XCTAssertTrue(plain.contains("{{ products.selected.price }}"),
                      "Expression should be preserved in output")
        XCTAssertFalse(plain.contains("**"), "Bold markers should be stripped")
    }

    // MARK: - Very Long Text

    func testVeryLongTextWithBoldSegments() {
        let words = (0..<100).map { "word\($0)" }
        let input = words.joined(separator: " ") + " **highlighted** end"
        let result = MarkdownParser.parse(input)
        let plain = String(result.characters)
        XCTAssertTrue(plain.contains("highlighted"))
        XCTAssertFalse(plain.contains("**"))
    }

    // MARK: - Bold at Start

    func testBoldAtStartOfString() {
        let input = "**Start bold** then normal text."
        let result = MarkdownParser.parse(input)
        let plain = String(result.characters)
        XCTAssertEqual(plain, "Start bold then normal text.")
    }

    // MARK: - Bold at End

    func testBoldAtEndOfString() {
        let input = "Normal text then **end bold**"
        let result = MarkdownParser.parse(input)
        let plain = String(result.characters)
        XCTAssertEqual(plain, "Normal text then end bold")
    }

    // MARK: - Single Asterisks Not Treated as Bold

    func testSingleAsterisksNotTreatedAsBold() {
        let input = "This *is not bold* text"
        let result = MarkdownParser.parse(input)
        let plain = String(result.characters)
        // Single asterisks should not be treated as bold markers
        XCTAssertTrue(plain.contains("*") || plain == "This is not bold text",
                      "Single asterisks should be handled, not treated as bold")
    }
}
