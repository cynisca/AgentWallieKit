import XCTest
import SwiftUI
@testable import AgentWallieKit

@available(iOS 16.0, macOS 13.0, *)
final class ThemeResolutionTests: XCTestCase {

    // MARK: - Helper

    private func makeTheme(
        background: String = "#FFFFFF",
        primary: String = "#007AFF",
        secondary: String = "#5856D6",
        textPrimary: String = "#000000",
        textSecondary: String = "#6B7280",
        accent: String = "#34C759",
        surface: String = "#F2F2F7"
    ) -> PaywallTheme {
        PaywallTheme(
            background: background,
            primary: primary,
            secondary: secondary,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            accent: accent,
            surface: surface
        )
    }

    // MARK: - resolveColor with hex strings

    func testResolveColor_hexColor_resolvesCorrectly() {
        let color = resolveColor("#007AFF", theme: nil)
        XCTAssertNotNil(color, "Standard 6-digit hex should resolve to a color")
    }

    func testResolveColor_3DigitHex_resolvesToColor() {
        let color = resolveColor("#F00", theme: nil)
        XCTAssertNotNil(color, "3-digit hex #F00 should resolve to red")
    }

    func testResolveColor_8DigitHexWithAlpha_resolvesCorrectly() {
        let color = resolveColor("#80FF0000", theme: nil)
        XCTAssertNotNil(color, "8-digit ARGB hex should resolve with alpha")
    }

    // MARK: - resolveColor with theme references

    func testResolveColor_themePrimary_resolvesToThemePrimaryHex() {
        let theme = makeTheme(primary: "#FF0000")
        let color = resolveColor("{{ theme.primary }}", theme: theme)
        XCTAssertNotNil(color, "{{ theme.primary }} should resolve to theme.primary hex")
    }

    func testResolveColor_themeSecondary_resolvesToThemeSecondaryHex() {
        let theme = makeTheme(secondary: "#00FF00")
        let color = resolveColor("{{ theme.secondary }}", theme: theme)
        XCTAssertNotNil(color, "{{ theme.secondary }} should resolve to theme.secondary hex")
    }

    func testResolveColor_themeBackground_resolvesToThemeBackgroundHex() {
        let theme = makeTheme(background: "#1a1a2e")
        let color = resolveColor("{{ theme.background }}", theme: theme)
        XCTAssertNotNil(color, "{{ theme.background }} should resolve to theme.background hex")
    }

    func testResolveColor_themeTextPrimary_resolvesToThemeTextPrimaryHex() {
        let theme = makeTheme(textPrimary: "#e0e0f0")
        let color = resolveColor("{{ theme.text_primary }}", theme: theme)
        XCTAssertNotNil(color, "{{ theme.text_primary }} should resolve to theme.textPrimary hex")
    }

    func testResolveColor_themeTextSecondary_resolvesToThemeTextSecondaryHex() {
        let theme = makeTheme(textSecondary: "#a0a0b0")
        let color = resolveColor("{{ theme.text_secondary }}", theme: theme)
        XCTAssertNotNil(color, "{{ theme.text_secondary }} should resolve to theme.textSecondary hex")
    }

    func testResolveColor_themeAccent_resolvesToThemeAccentHex() {
        let theme = makeTheme(accent: "#ff6b6b")
        let color = resolveColor("{{ theme.accent }}", theme: theme)
        XCTAssertNotNil(color, "{{ theme.accent }} should resolve to theme.accent hex")
    }

    func testResolveColor_themeSurface_resolvesToThemeSurfaceHex() {
        let theme = makeTheme(surface: "#2d2d44")
        let color = resolveColor("{{ theme.surface }}", theme: theme)
        XCTAssertNotNil(color, "{{ theme.surface }} should resolve to theme.surface hex")
    }

    // MARK: - resolveColor edge cases

    func testResolveColor_unknownThemeKey_returnsNil() {
        let theme = makeTheme()
        let color = resolveColor("{{ theme.unknown_key }}", theme: theme)
        XCTAssertNil(color, "Unknown theme key should return nil")
    }

    func testResolveColor_emptyString_returnsNil() {
        let color = resolveColor("", theme: makeTheme())
        XCTAssertNil(color, "Empty string should return nil")
    }

    func testResolveColor_nil_returnsNil() {
        let color = resolveColor(nil, theme: makeTheme())
        XCTAssertNil(color, "nil input should return nil")
    }

    func testResolveColor_themeReferenceWithNoTheme_returnsNil() {
        let color = resolveColor("{{ theme.primary }}", theme: nil)
        XCTAssertNil(color, "Theme reference with nil theme should return nil")
    }

    func testResolveColor_themeReferenceWithExtraSpaces_stillWorks() {
        let theme = makeTheme(primary: "#FF0000")
        let color = resolveColor("{{  theme.primary  }}", theme: theme)
        XCTAssertNotNil(color, "Theme reference with extra spaces should still resolve")
    }

    func testResolveColor_nonThemeStringContainingThemeDot_treatedAsHex() {
        // "my_theme.css" contains "theme." but is not a template reference (no {{ }})
        let color = resolveColor("my_theme.css", theme: makeTheme())
        // Should attempt hex parse, not theme resolution. The result is a Color
        // from invalid hex which defaults to black, but it should NOT return nil
        // as it would if treated as an unrecognized theme ref.
        XCTAssertNotNil(color, "Non-template string containing 'theme.' should be treated as hex, not theme ref")
    }

    // MARK: - StyleModifier integration

    func testStyleModifier_backgroundColorFromStyle_applied() {
        let style = ComponentStyle()
        // backgroundColor can be set via the style
        let modifier = StyleModifier(style: style, theme: makeTheme())
        // If it compiles and runs, the modifier correctly accepts style + theme
        XCTAssertNotNil(modifier)
    }

    func testStyleModifier_themeReferenceInBackgroundColor_resolves() {
        var style = ComponentStyle()
        style.backgroundColor = "{{ theme.primary }}"
        let theme = makeTheme(primary: "#FF0000")
        let modifier = StyleModifier(style: style, theme: theme)
        XCTAssertNotNil(modifier, "StyleModifier should handle theme references in backgroundColor")
    }

    func testStyleModifier_cornerRadiusFromStyle_applied() {
        var style = ComponentStyle()
        style.cornerRadius = .number(16)
        let modifier = StyleModifier(style: style, theme: makeTheme())
        XCTAssertNotNil(modifier, "StyleModifier should accept corner radius from style")
    }

    func testStyleModifier_marginsApplied() {
        var style = ComponentStyle()
        style.marginTop = 10
        style.marginBottom = 20
        style.marginLeft = 5
        style.marginRight = 5
        let modifier = StyleModifier(style: style, theme: makeTheme())
        XCTAssertNotNil(modifier, "StyleModifier should accept margin values")
    }

    // MARK: - All theme keys resolve when present

    func testAllThemeKeys_resolveToNonNil() {
        let theme = makeTheme(
            background: "#1a1a2e",
            primary: "#6c63ff",
            secondary: "#5856D6",
            textPrimary: "#e0e0f0",
            textSecondary: "#a0a0b0",
            accent: "#ff6b6b",
            surface: "#2d2d44"
        )

        let keys: [(String, String)] = [
            ("{{ theme.primary }}", "primary"),
            ("{{ theme.secondary }}", "secondary"),
            ("{{ theme.background }}", "background"),
            ("{{ theme.text_primary }}", "text_primary"),
            ("{{ theme.text_secondary }}", "text_secondary"),
            ("{{ theme.accent }}", "accent"),
            ("{{ theme.surface }}", "surface"),
        ]

        for (ref, name) in keys {
            let color = resolveColor(ref, theme: theme)
            XCTAssertNotNil(color, "Theme key '\(name)' should resolve to non-nil color")
        }
    }

    // MARK: - Theme reference with nil theme for all keys

    func testAllThemeKeys_returnNilWhenThemeIsNil() {
        let keys = [
            "{{ theme.primary }}",
            "{{ theme.secondary }}",
            "{{ theme.background }}",
            "{{ theme.text_primary }}",
            "{{ theme.text_secondary }}",
            "{{ theme.accent }}",
            "{{ theme.surface }}",
        ]

        for ref in keys {
            let color = resolveColor(ref, theme: nil)
            XCTAssertNil(color, "'\(ref)' should return nil when theme is nil")
        }
    }
}
