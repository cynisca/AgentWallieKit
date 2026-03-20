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

    private let sampleResolvedProducts: [ResolvedProductInfo] = [
        ResolvedProductInfo(
            slot: "primary",
            label: "Monthly - $9.99",
            productId: "com.app.monthly",
            storeProductId: "com.app.monthly",
            price: "$9.99",
            pricePerMonth: "$9.99",
            period: "month",
            periodLabel: "/mo",
            trialPeriod: "7 days",
            trialPrice: "Free",
            savingsPercentage: nil,
            rawPrice: Decimal(string: "9.99")
        ),
        ResolvedProductInfo(
            slot: "secondary",
            label: "Yearly - $49.99",
            productId: "com.app.yearly",
            storeProductId: "com.app.yearly",
            price: "$49.99",
            pricePerMonth: "$4.17",
            period: "year",
            periodLabel: "/yr",
            trialPeriod: nil,
            trialPrice: nil,
            savingsPercentage: 58,
            rawPrice: Decimal(string: "49.99")
        ),
    ]

    private func resolver(
        products: [ProductSlot]? = nil,
        selectedIndex: Int = 0,
        theme: PaywallTheme? = nil,
        userAttributes: [String: Any]? = nil,
        resolvedProducts: [ResolvedProductInfo]? = nil
    ) -> ExpressionResolver {
        ExpressionResolver(
            products: products,
            selectedProductIndex: selectedIndex,
            theme: theme,
            userAttributes: userAttributes,
            resolvedProducts: resolvedProducts
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

    // MARK: - Resolved Product Expressions

    func testSelectedProductPrice() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 0,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(
            r.resolve("{{ products.selected.price }}"),
            "$9.99"
        )
    }

    func testPrimaryProductSavingsPercentage() {
        let r = resolver(
            products: sampleProducts,
            resolvedProducts: sampleResolvedProducts
        )
        // primary has nil savings
        let text = "{{ products.primary.savings_percentage }}"
        XCTAssertEqual(r.resolve(text), text) // stays as-is when nil

        // secondary has 58% savings
        XCTAssertEqual(
            r.resolve("{{ products.secondary.savings_percentage }}"),
            "58"
        )
    }

    func testSelectedProductTrialPeriod() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 0,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(
            r.resolve("{{ products.selected.trial_period }}"),
            "7 days"
        )
    }

    func testSelectedProductPeriodLabel() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 0,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(
            r.resolve("{{ products.selected.period_label }}"),
            "/mo"
        )
    }

    func testSelectedProductHasTrial_True() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 0,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(
            r.resolve("{{ products.selected.has_trial }}"),
            "true"
        )
    }

    func testSelectedProductHasTrial_False() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 1,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(
            r.resolve("{{ products.selected.has_trial }}"),
            "false"
        )
    }

    func testMissingResolvedProducts_FallsBackGracefully() {
        // No resolvedProducts provided — price expressions stay as-is
        let r = resolver(products: sampleProducts, selectedIndex: 0)
        let text = "{{ products.selected.price }}"
        XCTAssertEqual(r.resolve(text), text)
    }

    func testResolvedProductPricePerMonth() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 1,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(
            r.resolve("{{ products.selected.price_per_month }}"),
            "$4.17"
        )
    }

    func testResolvedProductPeriod() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 1,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(
            r.resolve("{{ products.selected.period }}"),
            "year"
        )
    }

    func testSlotLookupWithResolvedProducts() {
        let r = resolver(
            products: sampleProducts,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(
            r.resolve("{{ products.secondary.price }}"),
            "$49.99"
        )
        XCTAssertEqual(
            r.resolve("{{ products.secondary.period_label }}"),
            "/yr"
        )
    }
}
