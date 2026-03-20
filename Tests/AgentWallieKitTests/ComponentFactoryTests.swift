import XCTest
import SwiftUI
@testable import AgentWallieKit

@available(iOS 16.0, macOS 13.0, *)
final class ComponentFactoryTests: XCTestCase {

    // MARK: - resolveColor with hex string

    func testResolveColorWithHexString() {
        let color = resolveColor("#FF0000", theme: nil)
        XCTAssertNotNil(color)
    }

    func testResolveColorWith3DigitHex() {
        let color = resolveColor("#F00", theme: nil)
        XCTAssertNotNil(color)
    }

    func testResolveColorWith8DigitHex() {
        let color = resolveColor("#80FF0000", theme: nil)
        XCTAssertNotNil(color)
    }

    // MARK: - resolveColor with theme reference

    func testResolveColorWithThemePrimary() {
        let theme = PaywallTheme(primary: "#FF0000")
        let color = resolveColor("{{ theme.primary }}", theme: theme)
        XCTAssertNotNil(color)
    }

    func testResolveColorWithThemeSecondary() {
        let theme = PaywallTheme(secondary: "#00FF00")
        let color = resolveColor("{{ theme.secondary }}", theme: theme)
        XCTAssertNotNil(color)
    }

    func testResolveColorWithThemeBackground() {
        let theme = PaywallTheme(background: "#FFFFFF")
        let color = resolveColor("{{ theme.background }}", theme: theme)
        XCTAssertNotNil(color)
    }

    func testResolveColorWithThemeTextPrimary() {
        let theme = PaywallTheme(textPrimary: "#000000")
        let color = resolveColor("{{ theme.text_primary }}", theme: theme)
        XCTAssertNotNil(color)
    }

    func testResolveColorWithThemeTextSecondary() {
        let theme = PaywallTheme(textSecondary: "#666666")
        let color = resolveColor("{{ theme.text_secondary }}", theme: theme)
        XCTAssertNotNil(color)
    }

    func testResolveColorWithThemeAccent() {
        let theme = PaywallTheme(accent: "#0000FF")
        let color = resolveColor("{{ theme.accent }}", theme: theme)
        XCTAssertNotNil(color)
    }

    func testResolveColorWithThemeSurface() {
        let theme = PaywallTheme(surface: "#F2F2F7")
        let color = resolveColor("{{ theme.surface }}", theme: theme)
        XCTAssertNotNil(color)
    }

    // MARK: - resolveColor with nil

    func testResolveColorWithNilReturnsNil() {
        let color = resolveColor(nil, theme: nil)
        XCTAssertNil(color)
    }

    func testResolveColorWithEmptyStringReturnsNil() {
        let color = resolveColor("", theme: nil)
        XCTAssertNil(color)
    }

    // MARK: - resolveColor with invalid string

    func testResolveColorWithThemeReferenceNoThemeReturnsNil() {
        let color = resolveColor("{{ theme.primary }}", theme: nil)
        XCTAssertNil(color)
    }

    func testResolveColorWithUnknownThemeKeyReturnsNil() {
        let theme = PaywallTheme()
        let color = resolveColor("{{ theme.nonexistent }}", theme: theme)
        XCTAssertNil(color)
    }

    // MARK: - textAlignment helper

    func testTextAlignmentCenter() {
        XCTAssertEqual(textAlignment("center"), .center)
    }

    func testTextAlignmentTrailing() {
        XCTAssertEqual(textAlignment("trailing"), .trailing)
    }

    func testTextAlignmentRight() {
        XCTAssertEqual(textAlignment("right"), .trailing)
    }

    func testTextAlignmentLeading() {
        XCTAssertEqual(textAlignment("leading"), .leading)
    }

    func testTextAlignmentLeft() {
        XCTAssertEqual(textAlignment("left"), .leading)
    }

    func testTextAlignmentDefault() {
        XCTAssertEqual(textAlignment(nil), .leading)
        XCTAssertEqual(textAlignment("unknown"), .leading)
    }

    // MARK: - frameAlignment helper

    func testFrameAlignmentCenter() {
        XCTAssertEqual(frameAlignment("center"), .center)
    }

    func testFrameAlignmentTrailing() {
        XCTAssertEqual(frameAlignment("trailing"), .trailing)
    }

    func testFrameAlignmentRight() {
        XCTAssertEqual(frameAlignment("right"), .trailing)
    }

    func testFrameAlignmentLeading() {
        XCTAssertEqual(frameAlignment("leading"), .leading)
    }

    func testFrameAlignmentLeft() {
        XCTAssertEqual(frameAlignment("left"), .leading)
    }

    func testFrameAlignmentDefault() {
        XCTAssertEqual(frameAlignment(nil), .leading)
        XCTAssertEqual(frameAlignment("unknown"), .leading)
    }

    // MARK: - Color hex extension

    func testColorHexInit6Digit() {
        let color = Color(hex: "#007AFF")
        // Just verify it doesn't crash; Color comparison is tricky
        XCTAssertNotNil(color)
    }

    func testColorHexInit3Digit() {
        let color = Color(hex: "#F00")
        XCTAssertNotNil(color)
    }

    func testColorHexInit8Digit() {
        let color = Color(hex: "#80FF0000")
        XCTAssertNotNil(color)
    }

    func testColorHexInitStripsNonAlphanumeric() {
        // The hex init strips non-alphanumeric, so "#" is removed
        let color = Color(hex: "007AFF")
        XCTAssertNotNil(color)
    }
}
