import XCTest
@testable import AgentWallieKit

/// Focused tests for product expression resolution, particularly for resolved product fields
/// like price, period, trial info, and savings. These verify the fix for limitation #2
/// in the SDK limitations report.
@available(iOS 16.0, *)
final class ExpressionResolverProductTests: XCTestCase {

    // MARK: - Fixtures

    private let sampleProducts: [ProductSlot] = [
        ProductSlot(slot: "primary", label: "Annual", productId: "com.app.annual"),
        ProductSlot(slot: "secondary", label: "Weekly", productId: "com.app.weekly"),
    ]

    private let sampleResolvedProducts: [ResolvedProductInfo] = [
        ResolvedProductInfo(
            slot: "primary",
            label: "Annual",
            productId: "com.app.annual",
            storeProductId: "com.app.annual",
            price: "$29.99",
            pricePerMonth: "$2.50",
            period: "year",
            periodLabel: "/yr",
            trialPeriod: "3 days",
            trialPrice: "Free",
            savingsPercentage: 88,
            rawPrice: Decimal(string: "29.99")
        ),
        ResolvedProductInfo(
            slot: "secondary",
            label: "Weekly",
            productId: "com.app.weekly",
            storeProductId: "com.app.weekly",
            price: "$4.99",
            pricePerMonth: "$21.62",
            period: "week",
            periodLabel: "/wk",
            trialPeriod: nil,
            trialPrice: nil,
            savingsPercentage: nil,
            rawPrice: Decimal(string: "4.99")
        ),
    ]

    private func resolver(
        products: [ProductSlot]? = nil,
        selectedIndex: Int = 0,
        resolvedProducts: [ResolvedProductInfo]? = nil
    ) -> ExpressionResolver {
        ExpressionResolver(
            products: products,
            selectedProductIndex: selectedIndex,
            theme: nil,
            userAttributes: nil,
            resolvedProducts: resolvedProducts
        )
    }

    // MARK: - Selected Product Price

    func testSelectedProductPrice_resolvesWhenResolvedProductsHasData() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 0,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(
            r.resolve("{{ products.selected.price }}"),
            "$29.99"
        )
    }

    func testSelectedProductPrice_returnsEmptyOrRawWhenResolvedProductsNil() {
        let r = resolver(products: sampleProducts, selectedIndex: 0, resolvedProducts: nil)
        let result = r.resolve("{{ products.selected.price }}")
        // When no resolved products, the expression should stay as-is (unresolved)
        XCTAssertEqual(result, "{{ products.selected.price }}")
    }

    func testSelectedProductPrice_returnsEmptyOrRawWhenResolvedProductsEmpty() {
        let r = resolver(products: sampleProducts, selectedIndex: 0, resolvedProducts: [])
        let result = r.resolve("{{ products.selected.price }}")
        // When resolved products is empty array, the expression should stay as-is
        XCTAssertEqual(result, "{{ products.selected.price }}")
    }

    // MARK: - Changing Selected Index

    func testChangingSelectedProductIndex_changesResolvedPrice() {
        let r0 = resolver(
            products: sampleProducts,
            selectedIndex: 0,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(r0.resolve("{{ products.selected.price }}"), "$29.99")

        let r1 = resolver(
            products: sampleProducts,
            selectedIndex: 1,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(r1.resolve("{{ products.selected.price }}"), "$4.99")
    }

    // MARK: - Period

    func testSelectedProductPeriod_resolvesToPeriodString() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 0,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(r.resolve("{{ products.selected.period }}"), "year")
    }

    // MARK: - Period Label

    func testSelectedProductPeriodLabel_resolvesToShortLabel() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 0,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(r.resolve("{{ products.selected.period_label }}"), "/yr")

        let r2 = resolver(
            products: sampleProducts,
            selectedIndex: 1,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(r2.resolve("{{ products.selected.period_label }}"), "/wk")
    }

    // MARK: - Trial Period

    func testSelectedProductTrialPeriod_resolvesWhenTrialExists() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 0,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(r.resolve("{{ products.selected.trial_period }}"), "3 days")
    }

    func testSelectedProductTrialPeriod_returnsEmptyOrRawWhenNoTrial() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 1,
            resolvedProducts: sampleResolvedProducts
        )
        let result = r.resolve("{{ products.selected.trial_period }}")
        // Weekly product has no trial — expression should stay as-is or return empty
        XCTAssertTrue(
            result == "{{ products.selected.trial_period }}" || result == "",
            "Expected unresolved expression or empty string, got: \(result)"
        )
    }

    // MARK: - Savings Percentage

    func testSelectedProductSavingsPercentage_resolvesToNumber() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 0,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(r.resolve("{{ products.selected.savings_percentage }}"), "88")
    }

    // MARK: - Has Trial

    func testSelectedProductHasTrial_resolvesToTrueWhenTrialExists() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 0,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(r.resolve("{{ products.selected.has_trial }}"), "true")
    }

    func testSelectedProductHasTrial_resolvesToFalseWhenNoTrial() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 1,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(r.resolve("{{ products.selected.has_trial }}"), "false")
    }

    // MARK: - Slot Name Lookup

    func testProductsBySlotName_primaryPrice() {
        let r = resolver(
            products: sampleProducts,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(r.resolve("{{ products.primary.price }}"), "$29.99")
    }

    func testProductsBySlotName_secondaryPrice() {
        let r = resolver(
            products: sampleProducts,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(r.resolve("{{ products.secondary.price }}"), "$4.99")
    }

    // MARK: - Nonexistent Slot

    func testNonexistentSlot_returnsRawExpression() {
        let r = resolver(
            products: sampleProducts,
            resolvedProducts: sampleResolvedProducts
        )
        let text = "{{ products.nonexistent.price }}"
        XCTAssertEqual(r.resolve(text), text)
    }

    // MARK: - Multiple Product References in One String

    func testMultipleProductReferencesInOneString() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 0,
            resolvedProducts: sampleResolvedProducts
        )
        let input = "{{ products.selected.price }}/{{ products.selected.period }}"
        let result = r.resolve(input)
        XCTAssertEqual(result, "$29.99/year")
    }

    func testMixedProductAndSlotReferences() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 0,
            resolvedProducts: sampleResolvedProducts
        )
        let input = "Annual: {{ products.primary.price }}{{ products.primary.period_label }}, Weekly: {{ products.secondary.price }}{{ products.secondary.period_label }}"
        let result = r.resolve(input)
        XCTAssertEqual(result, "Annual: $29.99/yr, Weekly: $4.99/wk")
    }

    // MARK: - Fallback to ProductSlot label

    func testFallbackToProductSlotLabel_whenResolvedProductsEmpty() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 0,
            resolvedProducts: nil
        )
        // Label should still resolve from ProductSlot
        XCTAssertEqual(
            r.resolve("{{ products.selected.label }}"),
            "Annual"
        )
    }

    func testFallbackToProductSlotLabel_bySlotName() {
        let r = resolver(
            products: sampleProducts,
            resolvedProducts: nil
        )
        XCTAssertEqual(
            r.resolve("{{ products.primary.label }}"),
            "Annual"
        )
        XCTAssertEqual(
            r.resolve("{{ products.secondary.label }}"),
            "Weekly"
        )
    }

    // MARK: - Price Per Month

    func testSelectedProductPricePerMonth() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 0,
            resolvedProducts: sampleResolvedProducts
        )
        XCTAssertEqual(r.resolve("{{ products.selected.price_per_month }}"), "$2.50")
    }

    // MARK: - Complex Real-World Expression

    func testRealWorldPricingExpression() {
        let r = resolver(
            products: sampleProducts,
            selectedIndex: 0,
            resolvedProducts: sampleResolvedProducts
        )
        let input = "Free for {{ products.selected.trial_period }}. {{ products.selected.price }}{{ products.selected.period_label }} after."
        let result = r.resolve(input)
        XCTAssertEqual(result, "Free for 3 days. $29.99/yr after.")
    }
}
