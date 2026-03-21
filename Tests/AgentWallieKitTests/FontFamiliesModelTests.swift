import XCTest
@testable import AgentWallieKit

final class FontFamiliesModelTests: XCTestCase {

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(value)
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - FontFamilies decoding

    func testFontFamiliesDecodeFromJSON() throws {
        let json = """
        {"display":"Georgia","heading":"Avenir","body":"Helvetica Neue","mono":"Courier"}
        """
        let data = json.data(using: .utf8)!
        let families = try JSONDecoder().decode(FontFamilies.self, from: data)
        XCTAssertEqual(families.display, "Georgia")
        XCTAssertEqual(families.heading, "Avenir")
        XCTAssertEqual(families.body, "Helvetica Neue")
        XCTAssertEqual(families.mono, "Courier")
    }

    func testFontFamiliesWithPartialFields() throws {
        let json = """
        {"display":"Georgia"}
        """
        let data = json.data(using: .utf8)!
        let families = try JSONDecoder().decode(FontFamilies.self, from: data)
        XCTAssertEqual(families.display, "Georgia")
        XCTAssertNil(families.heading)
        XCTAssertNil(families.body)
        XCTAssertNil(families.mono)
    }

    func testFontFamiliesRoundTrip() throws {
        let families = FontFamilies(display: "Georgia", heading: "Avenir", body: "Helvetica", mono: "Courier")
        let decoded = try roundTrip(families)
        XCTAssertEqual(decoded.display, "Georgia")
        XCTAssertEqual(decoded.heading, "Avenir")
        XCTAssertEqual(decoded.body, "Helvetica")
        XCTAssertEqual(decoded.mono, "Courier")
    }

    // MARK: - PaywallTheme with fontFamilies

    func testPaywallThemeWithFontFamiliesRoundTrip() throws {
        let theme = PaywallTheme(fontFamilies: FontFamilies(display: "Georgia", heading: "Avenir"))
        let decoded = try roundTrip(theme)
        XCTAssertNotNil(decoded.fontFamilies)
        XCTAssertEqual(decoded.fontFamilies?.display, "Georgia")
        XCTAssertEqual(decoded.fontFamilies?.heading, "Avenir")
        XCTAssertNil(decoded.fontFamilies?.body)
        XCTAssertNil(decoded.fontFamilies?.mono)
    }

    func testPaywallThemeWithoutFontFamilies() throws {
        let theme = PaywallTheme()
        let decoded = try roundTrip(theme)
        XCTAssertNil(decoded.fontFamilies)
    }

    func testPaywallThemeDecodesFromJSONWithFontFamilies() throws {
        let json = """
        {
            "background": "#FFFFFF",
            "primary": "#007AFF",
            "secondary": "#5856D6",
            "text_primary": "#000000",
            "text_secondary": "#6B7280",
            "accent": "#34C759",
            "surface": "#F2F2F7",
            "corner_radius": 12,
            "font_family": "system",
            "font_families": {
                "display": "Playfair Display",
                "heading": "Inter",
                "body": "Inter",
                "mono": "JetBrains Mono"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let theme = try JSONDecoder().decode(PaywallTheme.self, from: data)
        XCTAssertNotNil(theme.fontFamilies)
        XCTAssertEqual(theme.fontFamilies?.display, "Playfair Display")
        XCTAssertEqual(theme.fontFamilies?.heading, "Inter")
        XCTAssertEqual(theme.fontFamilies?.body, "Inter")
        XCTAssertEqual(theme.fontFamilies?.mono, "JetBrains Mono")
    }

    func testPaywallThemeDecodesFromJSONWithoutFontFamilies() throws {
        let json = """
        {
            "background": "#FFFFFF",
            "primary": "#007AFF",
            "secondary": "#5856D6",
            "text_primary": "#000000",
            "text_secondary": "#6B7280",
            "accent": "#34C759",
            "surface": "#F2F2F7",
            "corner_radius": 12,
            "font_family": "system"
        }
        """
        let data = json.data(using: .utf8)!
        let theme = try JSONDecoder().decode(PaywallTheme.self, from: data)
        XCTAssertNil(theme.fontFamilies)
    }

    // MARK: - ComponentStyle with fontFamily

    func testComponentStyleWithFontFamilyRoundTrip() throws {
        var style = ComponentStyle()
        style.fontFamily = "CustomFont"
        style.fontSize = 18
        let decoded = try roundTrip(style)
        XCTAssertEqual(decoded.fontFamily, "CustomFont")
        XCTAssertEqual(decoded.fontSize, 18)
    }

    func testComponentStyleDecodesFromJSONWithFontFamily() throws {
        let json = """
        {"font_size": 20, "font_family": "Roboto"}
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(ComponentStyle.self, from: data)
        XCTAssertEqual(style.fontFamily, "Roboto")
        XCTAssertEqual(style.fontSize, 20)
    }

    func testComponentStyleWithoutFontFamily() throws {
        let json = """
        {"font_size": 16}
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(ComponentStyle.self, from: data)
        XCTAssertNil(style.fontFamily)
        XCTAssertEqual(style.fontSize, 16)
    }
}
