import XCTest
@testable import AgentWallieKit

final class PaywallSettingsExtensionsTests: XCTestCase {

    // MARK: - Helper

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - close_button_style

    func testPaywallSettings_decodesCloseButtonStyleIcon() throws {
        let json = """
        {
            "presentation": "fullscreen",
            "close_button": true,
            "close_button_delay_ms": 0,
            "background_color": "#000000",
            "scroll_enabled": true,
            "safe_area_insets": true,
            "close_button_style": "icon"
        }
        """
        let data = json.data(using: .utf8)!
        let settings = try JSONDecoder().decode(PaywallSettings.self, from: data)
        XCTAssertEqual(settings.closeButtonStyle, "icon")
    }

    func testPaywallSettings_decodesCloseButtonStyleText() throws {
        let json = """
        {
            "presentation": "modal",
            "close_button": true,
            "close_button_delay_ms": 0,
            "background_color": "#FFFFFF",
            "scroll_enabled": true,
            "safe_area_insets": true,
            "close_button_style": "text"
        }
        """
        let data = json.data(using: .utf8)!
        let settings = try JSONDecoder().decode(PaywallSettings.self, from: data)
        XCTAssertEqual(settings.closeButtonStyle, "text")
    }

    func testPaywallSettings_closeButtonStyleDefaultsToNilWhenNotPresent() throws {
        let json = """
        {
            "presentation": "modal"
        }
        """
        let data = json.data(using: .utf8)!
        let settings = try JSONDecoder().decode(PaywallSettings.self, from: data)
        XCTAssertNil(settings.closeButtonStyle)
    }

    // MARK: - background_gradient

    func testPaywallSettings_decodesBackgroundGradient() throws {
        let json = """
        {
            "presentation": "fullscreen",
            "close_button": true,
            "close_button_delay_ms": 0,
            "background_color": "#06060f",
            "scroll_enabled": true,
            "safe_area_insets": true,
            "background_gradient": {
                "colors": ["#06060f", "#1a0a20"],
                "direction": "vertical"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let settings = try JSONDecoder().decode(PaywallSettings.self, from: data)
        XCTAssertNotNil(settings.backgroundGradient)
        XCTAssertEqual(settings.backgroundGradient?.colors, ["#06060f", "#1a0a20"])
        XCTAssertEqual(settings.backgroundGradient?.direction, "vertical")
    }

    func testPaywallSettings_backgroundGradientNilWhenNotPresent() throws {
        let json = """
        {
            "presentation": "modal"
        }
        """
        let data = json.data(using: .utf8)!
        let settings = try JSONDecoder().decode(PaywallSettings.self, from: data)
        XCTAssertNil(settings.backgroundGradient)
    }

    // MARK: - Round-Trip with All New Properties

    func testPaywallSettings_roundTripWithAllNewProperties() throws {
        let settings = PaywallSettings(
            presentation: .fullscreen,
            closeButton: true,
            closeButtonDelayMs: 500,
            backgroundColor: "#06060f",
            scrollEnabled: true,
            safeAreaInsets: true,
            backgroundGradient: BackgroundGradient(
                colors: ["#06060f", "#1a0a20"],
                direction: "vertical"
            ),
            closeButtonStyle: "text"
        )
        let decoded = try roundTrip(settings)
        XCTAssertEqual(decoded.presentation, .fullscreen)
        XCTAssertTrue(decoded.closeButton)
        XCTAssertEqual(decoded.closeButtonDelayMs, 500)
        XCTAssertEqual(decoded.backgroundColor, "#06060f")
        XCTAssertTrue(decoded.scrollEnabled)
        XCTAssertTrue(decoded.safeAreaInsets)
        XCTAssertNotNil(decoded.backgroundGradient)
        XCTAssertEqual(decoded.backgroundGradient?.colors, ["#06060f", "#1a0a20"])
        XCTAssertEqual(decoded.backgroundGradient?.direction, "vertical")
        XCTAssertEqual(decoded.closeButtonStyle, "text")
    }

    // MARK: - Gradient with Theme References

    func testPaywallSettings_backgroundGradientWithThemeReferences() throws {
        let json = """
        {
            "presentation": "fullscreen",
            "close_button": true,
            "close_button_delay_ms": 0,
            "background_color": "#000000",
            "scroll_enabled": true,
            "safe_area_insets": true,
            "background_gradient": {
                "colors": ["{{ theme.background }}", "{{ theme.surface }}"],
                "direction": "vertical"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let settings = try JSONDecoder().decode(PaywallSettings.self, from: data)
        XCTAssertNotNil(settings.backgroundGradient)
        XCTAssertEqual(settings.backgroundGradient?.colors.count, 2)
        XCTAssertEqual(settings.backgroundGradient?.colors[0], "{{ theme.background }}")
        XCTAssertEqual(settings.backgroundGradient?.colors[1], "{{ theme.surface }}")
    }

    // MARK: - Both background_color and background_gradient

    func testPaywallSettings_bothBackgroundColorAndGradientPresent() throws {
        let json = """
        {
            "presentation": "fullscreen",
            "close_button": true,
            "close_button_delay_ms": 0,
            "background_color": "#06060f",
            "scroll_enabled": true,
            "safe_area_insets": true,
            "background_gradient": {
                "colors": ["#06060f", "#1a0a20"],
                "direction": "vertical"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let settings = try JSONDecoder().decode(PaywallSettings.self, from: data)
        // Both should decode successfully; gradient takes priority at render time
        XCTAssertEqual(settings.backgroundColor, "#06060f")
        XCTAssertNotNil(settings.backgroundGradient)
        XCTAssertEqual(settings.backgroundGradient?.colors, ["#06060f", "#1a0a20"])
    }

    // MARK: - Gradient Directions

    func testPaywallSettings_gradientWithHorizontalDirection() throws {
        let json = """
        {
            "background_gradient": {
                "colors": ["#FF0000", "#0000FF"],
                "direction": "horizontal"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let settings = try JSONDecoder().decode(PaywallSettings.self, from: data)
        XCTAssertEqual(settings.backgroundGradient?.direction, "horizontal")
    }

    func testPaywallSettings_gradientWithNoDirection() throws {
        let json = """
        {
            "background_gradient": {
                "colors": ["#000000", "#FFFFFF"]
            }
        }
        """
        let data = json.data(using: .utf8)!
        let settings = try JSONDecoder().decode(PaywallSettings.self, from: data)
        XCTAssertNotNil(settings.backgroundGradient)
        XCTAssertNil(settings.backgroundGradient?.direction)
    }
}
