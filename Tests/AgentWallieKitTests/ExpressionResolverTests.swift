import XCTest
@testable import AgentWallieKit

@available(iOS 16.0, *)
final class ExpressionResolverTests: XCTestCase {

    private let sampleProducts: [ProductSlot] = [
        ProductSlot(slot: "primary", label: "Monthly - $9.99", productId: "com.app.monthly"),
        ProductSlot(slot: "secondary", label: "Yearly - $49.99", productId: "com.app.yearly"),
    ]

    private let sampleTheme = PaywallTheme(
        primary: "#007AFF",
        secondary: "#5856D6",
        fontFamily: "Inter"
    )

    private func resolver(
        products: [ProductSlot]? = nil,
        selectedIndex: Int = 0,
        theme: PaywallTheme? = nil,
        userAttributes: [String: Any]? = nil
    ) -> ExpressionResolver {
        ExpressionResolver(
            products: products,
            selectedProductIndex: selectedIndex,
            theme: theme,
            userAttributes: userAttributes
        )
    }

    // MARK: - No Expressions

    func testNoExpressionsReturnsSameText() {
        let r = resolver(products: sampleProducts, theme: sampleTheme)
        XCTAssertEqual(r.resolve("Hello, world!"), "Hello, world!")
    }

    func testEmptyTextReturnsEmpty() {
        let r = resolver()
        XCTAssertEqual(r.resolve(""), "")
    }

    // MARK: - Product Expressions

    func testSelectedProductLabel() {
        let r = resolver(products: sampleProducts, selectedIndex: 0)
        XCTAssertEqual(
            r.resolve("Plan: {{ products.selected.label }}"),
            "Plan: Monthly - $9.99"
        )
    }

    func testSelectedProductLabelSecondIndex() {
        let r = resolver(products: sampleProducts, selectedIndex: 1)
        XCTAssertEqual(
            r.resolve("{{ products.selected.label }}"),
            "Yearly - $49.99"
        )
    }

    func testSelectedProductSlot() {
        let r = resolver(products: sampleProducts, selectedIndex: 0)
        XCTAssertEqual(
            r.resolve("{{ products.selected.slot }}"),
            "primary"
        )
    }

    func testPrimarySlotLabel() {
        let r = resolver(products: sampleProducts)
        XCTAssertEqual(
            r.resolve("{{ products.primary.label }}"),
            "Monthly - $9.99"
        )
    }

    func testSecondarySlotLabel() {
        let r = resolver(products: sampleProducts)
        XCTAssertEqual(
            r.resolve("{{ products.secondary.label }}"),
            "Yearly - $49.99"
        )
    }

    // MARK: - User Attributes

    func testUserAttributeResolution() {
        let r = resolver(userAttributes: ["name": "Fahim", "plan": "pro"])
        XCTAssertEqual(
            r.resolve("Hello, {{ user.name }}!"),
            "Hello, Fahim!"
        )
    }

    func testUserAttributeNumericValue() {
        let r = resolver(userAttributes: ["session_count": 42])
        XCTAssertEqual(
            r.resolve("Sessions: {{ user.session_count }}"),
            "Sessions: 42"
        )
    }

    // MARK: - Theme Expressions

    func testThemeFontFamily() {
        let r = resolver(theme: sampleTheme)
        XCTAssertEqual(
            r.resolve("Font: {{ theme.font_family }}"),
            "Font: Inter"
        )
    }

    func testThemePrimary() {
        let r = resolver(theme: sampleTheme)
        XCTAssertEqual(
            r.resolve("{{ theme.primary }}"),
            "#007AFF"
        )
    }

    // MARK: - Multiple Expressions

    func testMultipleExpressionsInOneString() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 0,
            userAttributes: ["name": "Fahim"]
        )
        XCTAssertEqual(
            r.resolve("Hi {{ user.name }}, your plan is {{ products.selected.label }}"),
            "Hi Fahim, your plan is Monthly - $9.99"
        )
    }

    // MARK: - Unknown / Missing

    func testUnknownExpressionStaysAsIs() {
        let r = resolver()
        let text = "Value: {{ unknown.path }}"
        XCTAssertEqual(r.resolve(text), text)
    }

    func testNilProductsExpressionStaysAsIs() {
        let r = resolver(products: nil)
        let text = "{{ products.selected.label }}"
        XCTAssertEqual(r.resolve(text), text)
    }

    func testEmptyProductsExpressionStaysAsIs() {
        let r = resolver(products: [])
        let text = "{{ products.selected.label }}"
        XCTAssertEqual(r.resolve(text), text)
    }

    func testMissingUserAttributeStaysAsIs() {
        let r = resolver(userAttributes: [:])
        let text = "{{ user.nonexistent }}"
        XCTAssertEqual(r.resolve(text), text)
    }

    func testNilUserAttributesStaysAsIs() {
        let r = resolver(userAttributes: nil)
        let text = "{{ user.name }}"
        XCTAssertEqual(r.resolve(text), text)
    }

    func testUnknownThemeKeyStaysAsIs() {
        let r = resolver(theme: sampleTheme)
        let text = "{{ theme.nonexistent_key }}"
        XCTAssertEqual(r.resolve(text), text)
    }
}
