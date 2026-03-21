import XCTest
@testable import AgentWallieKit

final class StyleExtensionsTests: XCTestCase {

    // MARK: - Helper

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - glow_color Decoding

    func testComponentStyle_decodesGlowColorFromJSON() throws {
        let json = """
        { "glow_color": "#61FF0080" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(ComponentStyle.self, from: data)
        XCTAssertEqual(style.glowColor, "#61FF0080")
    }

    func testComponentStyle_encodesGlowColorToJSON() throws {
        var style = ComponentStyle()
        style.glowColor = "#ff0080"
        let data = try JSONEncoder().encode(style)
        let jsonString = String(data: data, encoding: .utf8)!
        XCTAssertTrue(jsonString.contains("glow_color"), "Encoded JSON should contain glow_color key")
        XCTAssertTrue(jsonString.contains("#ff0080"), "Encoded JSON should contain the glow_color value")
    }

    func testComponentStyle_roundTripWithGlowColor() throws {
        var style = ComponentStyle()
        style.glowColor = "#61FF0080"
        let decoded = try roundTrip(style)
        XCTAssertEqual(decoded.glowColor, "#61FF0080")
    }

    func testComponentStyle_glowColorNilWhenNotPresent() throws {
        let json = """
        { "background_color": "#FF0000" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(ComponentStyle.self, from: data)
        XCTAssertNil(style.glowColor)
    }

    func testComponentStyle_glowColorAsThemeReference() throws {
        let json = """
        { "glow_color": "{{ theme.primary }}" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(ComponentStyle.self, from: data)
        XCTAssertEqual(style.glowColor, "{{ theme.primary }}")
    }

    // MARK: - letter_spacing Decoding

    func testComponentStyle_decodesLetterSpacingFromJSON() throws {
        let json = """
        { "letter_spacing": 4 }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(ComponentStyle.self, from: data)
        XCTAssertEqual(style.letterSpacing, 4)
    }

    func testComponentStyle_encodesLetterSpacingToJSON() throws {
        var style = ComponentStyle()
        style.letterSpacing = 2.5
        let data = try JSONEncoder().encode(style)
        let jsonString = String(data: data, encoding: .utf8)!
        XCTAssertTrue(jsonString.contains("letter_spacing"), "Encoded JSON should contain letter_spacing key")
    }

    func testComponentStyle_roundTripWithLetterSpacing() throws {
        var style = ComponentStyle()
        style.letterSpacing = 3.0
        let decoded = try roundTrip(style)
        XCTAssertEqual(decoded.letterSpacing, 3.0)
    }

    func testComponentStyle_letterSpacingNilWhenNotPresent() throws {
        let json = """
        { "font_size": 16 }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(ComponentStyle.self, from: data)
        XCTAssertNil(style.letterSpacing)
    }

    // MARK: - Combined Properties

    func testComponentStyle_bothGlowColorAndLetterSpacingSet() throws {
        var style = ComponentStyle()
        style.glowColor = "#ff0080"
        style.letterSpacing = 4.0
        let decoded = try roundTrip(style)
        XCTAssertEqual(decoded.glowColor, "#ff0080")
        XCTAssertEqual(decoded.letterSpacing, 4.0)
    }

    func testComponentStyle_allExistingPlusNewPropertiesRoundTrip() throws {
        var style = ComponentStyle()
        style.marginTop = 10
        style.marginBottom = 20
        style.paddingHorizontal = 16
        style.paddingVertical = 8
        style.backgroundColor = "#0d0d1a"
        style.cornerRadius = .number(12)
        style.fontSize = 18
        style.opacity = 0.95
        style.borderWidth = 2
        style.borderColor = "#1FFF0080"
        style.backgroundGradient = BackgroundGradient(colors: ["#000", "#FFF"], direction: "vertical")
        style.glowColor = "#61FF0080"
        style.letterSpacing = 4.0

        let decoded = try roundTrip(style)
        XCTAssertEqual(decoded.marginTop, 10)
        XCTAssertEqual(decoded.marginBottom, 20)
        XCTAssertEqual(decoded.paddingHorizontal, 16)
        XCTAssertEqual(decoded.paddingVertical, 8)
        XCTAssertEqual(decoded.backgroundColor, "#0d0d1a")
        XCTAssertEqual(decoded.cornerRadius?.doubleValue, 12)
        XCTAssertEqual(decoded.fontSize, 18)
        XCTAssertEqual(decoded.opacity, 0.95)
        XCTAssertEqual(decoded.borderWidth, 2)
        XCTAssertEqual(decoded.borderColor, "#1FFF0080")
        XCTAssertNotNil(decoded.backgroundGradient)
        XCTAssertEqual(decoded.backgroundGradient?.colors, ["#000", "#FFF"])
        XCTAssertEqual(decoded.backgroundGradient?.direction, "vertical")
        XCTAssertEqual(decoded.glowColor, "#61FF0080")
        XCTAssertEqual(decoded.letterSpacing, 4.0)
    }

    // MARK: - Full Component with Style

    func testCTAButtonWithGlowColor() throws {
        let json = """
        {
            "type": "cta_button",
            "id": "cta1",
            "props": { "text": "Start Trial", "action": "purchase" },
            "style": {
                "background_color": "#ff0080",
                "glow_color": "#61FF0080"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(PaywallComponent.self, from: data)
        if case .ctaButton(let d) = component {
            XCTAssertEqual(d.style?.glowColor, "#61FF0080")
            XCTAssertEqual(d.style?.backgroundColor, "#ff0080")
        } else {
            XCTFail("Expected cta_button component")
        }
    }

    func testTextComponentWithLetterSpacing() throws {
        let json = """
        {
            "type": "text",
            "id": "t1",
            "props": { "content": "UNLOCK PRO" },
            "style": { "letter_spacing": 4, "font_size": 12 }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(PaywallComponent.self, from: data)
        if case .text(let d) = component {
            XCTAssertEqual(d.style?.letterSpacing, 4)
            XCTAssertEqual(d.style?.fontSize, 12)
        } else {
            XCTFail("Expected text component")
        }
    }
}
