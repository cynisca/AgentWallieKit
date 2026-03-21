import XCTest
@testable import AgentWallieKit

final class ProductPickerRenderingTests: XCTestCase {

    // MARK: - Helper

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func decodePickerFromJSON(_ json: String) throws -> ProductPickerComponentData {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(ProductPickerComponentData.self, from: data)
    }

    // MARK: - Layout Decoding

    func testProductPickerProps_decodesLayoutCards() throws {
        let json = """
        {
            "type": "product_picker",
            "id": "pp1",
            "props": { "layout": "cards" }
        }
        """
        let picker = try decodePickerFromJSON(json)
        XCTAssertEqual(picker.props.layout, "cards")
    }

    func testProductPickerProps_decodesLayoutHorizontal() throws {
        let json = """
        {
            "type": "product_picker",
            "id": "pp2",
            "props": { "layout": "horizontal" }
        }
        """
        let picker = try decodePickerFromJSON(json)
        XCTAssertEqual(picker.props.layout, "horizontal")
    }

    func testProductPickerProps_decodesLayoutVertical() throws {
        let json = """
        {
            "type": "product_picker",
            "id": "pp3",
            "props": { "layout": "vertical" }
        }
        """
        let picker = try decodePickerFromJSON(json)
        XCTAssertEqual(picker.props.layout, "vertical")
    }

    // MARK: - Savings Text

    func testProductPickerProps_decodesSavingsText() throws {
        let json = """
        {
            "type": "product_picker",
            "id": "pp4",
            "props": { "layout": "horizontal", "savings_text": "BEST VALUE" }
        }
        """
        let picker = try decodePickerFromJSON(json)
        XCTAssertEqual(picker.props.savingsText, "BEST VALUE")
    }

    // MARK: - Show Price

    func testProductPickerProps_decodesShowPrice() throws {
        let json = """
        {
            "type": "product_picker",
            "id": "pp5",
            "props": { "layout": "horizontal", "show_price": true }
        }
        """
        let picker = try decodePickerFromJSON(json)
        XCTAssertEqual(picker.props.showPrice, true)
    }

    func testProductPickerProps_showPriceDefaultsToTrueWhenNotSpecified() throws {
        let json = """
        {
            "type": "product_picker",
            "id": "pp6",
            "props": { "layout": "horizontal" }
        }
        """
        let picker = try decodePickerFromJSON(json)
        // When show_price is not specified, it should default to true
        // (the fix agent will add this default)
        XCTAssertEqual(picker.props.showPrice, true)
    }

    func testProductPickerProps_showPriceFalse() throws {
        let json = """
        {
            "type": "product_picker",
            "id": "pp7",
            "props": { "layout": "cards", "show_price": false }
        }
        """
        let picker = try decodePickerFromJSON(json)
        XCTAssertEqual(picker.props.showPrice, false)
    }

    // MARK: - Selected Border Color

    func testProductPickerProps_selectedBorderColorAsHex() throws {
        let json = """
        {
            "type": "product_picker",
            "id": "pp8",
            "props": { "layout": "horizontal", "selected_border_color": "#ff0080" }
        }
        """
        let picker = try decodePickerFromJSON(json)
        XCTAssertEqual(picker.props.selectedBorderColor, "#ff0080")
    }

    func testProductPickerProps_selectedBorderColorAsThemeReference() throws {
        let json = """
        {
            "type": "product_picker",
            "id": "pp9",
            "props": { "layout": "horizontal", "selected_border_color": "{{ theme.primary }}" }
        }
        """
        let picker = try decodePickerFromJSON(json)
        XCTAssertEqual(picker.props.selectedBorderColor, "{{ theme.primary }}")
    }

    // MARK: - Full Round-Trip

    func testProductPickerComponentData_fullRoundTripAllProps() throws {
        let component = ProductPickerComponentData(
            id: "picker_full",
            props: ProductPickerComponentData.ProductPickerProps(
                layout: "cards",
                showSavingsBadge: true,
                savingsText: "Save 88%",
                selectedBorderColor: "#ff0080",
                showPrice: true
            )
        )
        let decoded = try roundTrip(component)
        XCTAssertEqual(decoded.id, "picker_full")
        XCTAssertEqual(decoded.type, "product_picker")
        XCTAssertEqual(decoded.props.layout, "cards")
        XCTAssertEqual(decoded.props.showSavingsBadge, true)
        XCTAssertEqual(decoded.props.savingsText, "Save 88%")
        XCTAssertEqual(decoded.props.selectedBorderColor, "#ff0080")
        XCTAssertEqual(decoded.props.showPrice, true)
    }

    func testProductPickerComponentData_roundTripMinimalProps() throws {
        let component = ProductPickerComponentData(
            id: "picker_min",
            props: ProductPickerComponentData.ProductPickerProps(
                layout: "vertical"
            )
        )
        let decoded = try roundTrip(component)
        XCTAssertEqual(decoded.id, "picker_min")
        XCTAssertEqual(decoded.type, "product_picker")
        XCTAssertEqual(decoded.props.layout, "vertical")
        XCTAssertNil(decoded.props.showSavingsBadge)
        XCTAssertNil(decoded.props.savingsText)
        XCTAssertNil(decoded.props.selectedBorderColor)
    }
}
