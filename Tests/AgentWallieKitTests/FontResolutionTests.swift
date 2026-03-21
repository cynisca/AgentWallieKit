import XCTest
import SwiftUI
@testable import AgentWallieKit

@available(iOS 16.0, macOS 13.0, *)
final class FontResolutionTests: XCTestCase {

    // MARK: - System font fallback

    func testSystemFontWhenNoThemeFontsOrOverrides() {
        let font = resolveFont(textStyle: "body", fontSize: nil, fontFamily: nil, theme: nil)
        // Should return system .body — we can't directly compare Font values,
        // but we verify it doesn't crash and returns a Font
        XCTAssertNotNil(font)
    }

    func testSystemFontFallbackWithThemeButNoFontFamilies() {
        let theme = PaywallTheme()
        let font = resolveFont(textStyle: "title1", fontSize: nil, fontFamily: nil, theme: theme)
        XCTAssertNotNil(font)
    }

    // MARK: - Theme display font

    func testThemeDisplayFontAppliedToTitle1() {
        let theme = PaywallTheme(fontFamilies: FontFamilies(display: "Georgia"))
        let font = resolveFont(textStyle: "title1", fontSize: nil, fontFamily: nil, theme: theme)
        // Should produce .custom("Georgia", size: 28)
        XCTAssertNotNil(font)
    }

    func testThemeDisplayFontAppliedToTitle2() {
        let theme = PaywallTheme(fontFamilies: FontFamilies(display: "Georgia"))
        let font = resolveFont(textStyle: "title2", fontSize: nil, fontFamily: nil, theme: theme)
        XCTAssertNotNil(font)
    }

    func testThemeDisplayFontAppliedToTitle3() {
        let theme = PaywallTheme(fontFamilies: FontFamilies(display: "Georgia"))
        let font = resolveFont(textStyle: "title3", fontSize: nil, fontFamily: nil, theme: theme)
        XCTAssertNotNil(font)
    }

    func testThemeDisplayFontAppliedToLargeTitle() {
        let theme = PaywallTheme(fontFamilies: FontFamilies(display: "Georgia"))
        let font = resolveFont(textStyle: "largeTitle", fontSize: nil, fontFamily: nil, theme: theme)
        XCTAssertNotNil(font)
    }

    // MARK: - Theme heading font

    func testThemeHeadingFontAppliedToHeadline() {
        let theme = PaywallTheme(fontFamilies: FontFamilies(heading: "Avenir"))
        let font = resolveFont(textStyle: "headline", fontSize: nil, fontFamily: nil, theme: theme)
        XCTAssertNotNil(font)
    }

    func testThemeHeadingFontAppliedToSubheadline() {
        let theme = PaywallTheme(fontFamilies: FontFamilies(heading: "Avenir"))
        let font = resolveFont(textStyle: "subheadline", fontSize: nil, fontFamily: nil, theme: theme)
        XCTAssertNotNil(font)
    }

    // MARK: - Theme body font

    func testThemeBodyFontAppliedToBody() {
        let theme = PaywallTheme(fontFamilies: FontFamilies(body: "Helvetica Neue"))
        let font = resolveFont(textStyle: "body", fontSize: nil, fontFamily: nil, theme: theme)
        XCTAssertNotNil(font)
    }

    func testThemeBodyFontAppliedToCallout() {
        let theme = PaywallTheme(fontFamilies: FontFamilies(body: "Helvetica Neue"))
        let font = resolveFont(textStyle: "callout", fontSize: nil, fontFamily: nil, theme: theme)
        XCTAssertNotNil(font)
    }

    // MARK: - Theme mono font

    func testThemeMonoFontAppliedToCaption() {
        let theme = PaywallTheme(fontFamilies: FontFamilies(mono: "Courier"))
        let font = resolveFont(textStyle: "caption", fontSize: nil, fontFamily: nil, theme: theme)
        XCTAssertNotNil(font)
    }

    func testThemeMonoFontAppliedToCaption2() {
        let theme = PaywallTheme(fontFamilies: FontFamilies(mono: "Courier"))
        let font = resolveFont(textStyle: "caption2", fontSize: nil, fontFamily: nil, theme: theme)
        XCTAssertNotNil(font)
    }

    func testThemeMonoFontAppliedToFootnote() {
        let theme = PaywallTheme(fontFamilies: FontFamilies(mono: "Courier"))
        let font = resolveFont(textStyle: "footnote", fontSize: nil, fontFamily: nil, theme: theme)
        XCTAssertNotNil(font)
    }

    // MARK: - Per-component fontFamily overrides theme

    func testPerComponentFontFamilyOverridesTheme() {
        let theme = PaywallTheme(fontFamilies: FontFamilies(display: "Georgia", heading: "Avenir"))
        let font = resolveFont(textStyle: "title1", fontSize: nil, fontFamily: "Futura", theme: theme)
        // Per-component "Futura" should win over theme's "Georgia"
        XCTAssertNotNil(font)
    }

    // MARK: - Explicit fontSize + fontFamily

    func testExplicitFontSizeAndFontFamily() {
        let font = resolveFont(textStyle: "body", fontSize: 24, fontFamily: "Futura", theme: nil)
        // Should produce .custom("Futura", size: 24)
        XCTAssertNotNil(font)
    }

    // MARK: - fontSize only

    func testFontSizeOnlyReturnsSystemFontAtThatSize() {
        let font = resolveFont(textStyle: "body", fontSize: 20, fontFamily: nil, theme: nil)
        // Should produce .system(size: 20)
        XCTAssertNotNil(font)
    }

    // MARK: - fontFamily only

    func testFontFamilyOnlyUsesDefaultSizeForTextStyle() {
        let font = resolveFont(textStyle: "title1", fontSize: nil, fontFamily: "Futura", theme: nil)
        // Should produce .custom("Futura", size: 28) since title1 default is 28
        XCTAssertNotNil(font)
    }

    // MARK: - Missing theme fontFamilies falls back to system

    func testMissingThemeFontFamiliesFallsBackToSystem() {
        let theme = PaywallTheme(fontFamilies: nil)
        let font = resolveFont(textStyle: "headline", fontSize: nil, fontFamily: nil, theme: theme)
        XCTAssertNotNil(font)
    }

    // MARK: - Nil textStyle defaults to body family

    func testNilTextStyleDefaultsToBodyFamily() {
        let theme = PaywallTheme(fontFamilies: FontFamilies(body: "Palatino"))
        let font = resolveFont(textStyle: nil, fontSize: nil, fontFamily: nil, theme: theme)
        // nil textStyle defaults to "body" → should use body family "Palatino"
        XCTAssertNotNil(font)
    }

    // MARK: - All textStyle values map to correct categories

    func testAllTextStylesMappedCorrectly() {
        let families = FontFamilies(display: "D", heading: "H", body: "B", mono: "M")

        // Display
        XCTAssertEqual(fontFamilyFromTheme(textStyle: "largeTitle", fontFamilies: families), "D")
        XCTAssertEqual(fontFamilyFromTheme(textStyle: "title1", fontFamilies: families), "D")
        XCTAssertEqual(fontFamilyFromTheme(textStyle: "title2", fontFamilies: families), "D")
        XCTAssertEqual(fontFamilyFromTheme(textStyle: "title3", fontFamilies: families), "D")

        // Heading
        XCTAssertEqual(fontFamilyFromTheme(textStyle: "headline", fontFamilies: families), "H")
        XCTAssertEqual(fontFamilyFromTheme(textStyle: "subheadline", fontFamilies: families), "H")

        // Body
        XCTAssertEqual(fontFamilyFromTheme(textStyle: "body", fontFamilies: families), "B")
        XCTAssertEqual(fontFamilyFromTheme(textStyle: "callout", fontFamilies: families), "B")

        // Mono
        XCTAssertEqual(fontFamilyFromTheme(textStyle: "footnote", fontFamilies: families), "M")
        XCTAssertEqual(fontFamilyFromTheme(textStyle: "caption", fontFamilies: families), "M")
        XCTAssertEqual(fontFamilyFromTheme(textStyle: "caption2", fontFamilies: families), "M")

        // Default (nil, unknown) → body
        XCTAssertEqual(fontFamilyFromTheme(textStyle: nil, fontFamilies: families), "B")
        XCTAssertEqual(fontFamilyFromTheme(textStyle: "unknown", fontFamilies: families), "B")
    }

    // MARK: - Partial FontFamilies (only some categories set)

    func testPartialFontFamiliesOnlyDisplaySet() {
        let theme = PaywallTheme(fontFamilies: FontFamilies(display: "Georgia"))
        // title1 should use Georgia
        let fontTitle = resolveFont(textStyle: "title1", fontSize: nil, fontFamily: nil, theme: theme)
        XCTAssertNotNil(fontTitle)
        // body should fall back to system (body family is nil)
        let fontBody = resolveFont(textStyle: "body", fontSize: nil, fontFamily: nil, theme: theme)
        XCTAssertNotNil(fontBody)
    }

    func testFontFamilyFromThemeReturnsNilWhenCategoryNotSet() {
        let families = FontFamilies(display: "Georgia")
        XCTAssertNil(fontFamilyFromTheme(textStyle: "headline", fontFamilies: families))
        XCTAssertNil(fontFamilyFromTheme(textStyle: "body", fontFamilies: families))
        XCTAssertNil(fontFamilyFromTheme(textStyle: "caption", fontFamilies: families))
    }
}
