import XCTest
@testable import AgentWallieKit

@available(iOS 16.0, *)
final class ProductResolverTests: XCTestCase {

    // MARK: - Helpers

    private func makeSlot(_ slot: String, label: String, productId: String? = nil) -> ProductSlot {
        ProductSlot(slot: slot, label: label, productId: productId)
    }

    private func makeAWProduct(
        id: String,
        storeProductId: String,
        store: StoreType = .apple,
        displayPrice: String? = nil,
        displayPeriod: String? = nil
    ) -> AWProduct {
        AWProduct(
            id: id,
            name: id,
            store: store,
            storeProductId: storeProductId,
            entitlements: [],
            displayPrice: displayPrice,
            displayPeriod: displayPeriod
        )
    }

    // MARK: - Savings Calculation

    func testSavingsCalculation_MonthlyAndYearly() {
        let slots = [
            makeSlot("primary", label: "Yearly", productId: "prod_yearly"),
            makeSlot("secondary", label: "Monthly", productId: "prod_monthly"),
        ]

        let products = [
            makeAWProduct(id: "prod_yearly", storeProductId: "com.app.yearly"),
            makeAWProduct(id: "prod_monthly", storeProductId: "com.app.monthly"),
        ]

        let storeProducts: [String: any StoreProductProviding] = [
            "com.app.monthly": MockStoreProduct(
                id: "com.app.monthly",
                displayPrice: "$9.99",
                price: Decimal(string: "9.99")!,
                subscriptionPeriodUnit: .month,
                subscriptionPeriodValue: 1
            ),
            "com.app.yearly": MockStoreProduct(
                id: "com.app.yearly",
                displayPrice: "$59.99",
                price: Decimal(string: "59.99")!,
                subscriptionPeriodUnit: .year,
                subscriptionPeriodValue: 1
            ),
        ]

        let resolved = ProductResolver.resolve(slots: slots, products: products, storeProducts: storeProducts)

        XCTAssertEqual(resolved.count, 2)

        // Yearly product: $59.99/yr = $4.99/mo vs $9.99/mo = ~50% savings
        let yearly = resolved.first(where: { $0.slot == "primary" })!
        XCTAssertNotNil(yearly.savingsPercentage)
        XCTAssertEqual(yearly.savingsPercentage, 50)

        // Monthly product should have no savings
        let monthly = resolved.first(where: { $0.slot == "secondary" })!
        XCTAssertNil(monthly.savingsPercentage)
    }

    func testSavingsWithNoMonthlyProduct_ReturnsNilSavings() {
        let slots = [
            makeSlot("primary", label: "Yearly", productId: "prod_yearly"),
        ]

        let products = [
            makeAWProduct(id: "prod_yearly", storeProductId: "com.app.yearly"),
        ]

        let storeProducts: [String: any StoreProductProviding] = [
            "com.app.yearly": MockStoreProduct(
                id: "com.app.yearly",
                displayPrice: "$59.99",
                price: Decimal(string: "59.99")!,
                subscriptionPeriodUnit: .year,
                subscriptionPeriodValue: 1
            ),
        ]

        let resolved = ProductResolver.resolve(slots: slots, products: products, storeProducts: storeProducts)
        XCTAssertNil(resolved[0].savingsPercentage)
    }

    // MARK: - Fallback to AWProduct

    func testFallbackToAWProductDisplayPrice_WhenNoStoreKitProduct() {
        let slots = [
            makeSlot("primary", label: "Monthly", productId: "prod_monthly"),
        ]

        let products = [
            makeAWProduct(
                id: "prod_monthly",
                storeProductId: "com.app.monthly",
                displayPrice: "$9.99",
                displayPeriod: "month"
            ),
        ]

        // No store products (empty cache)
        let storeProducts: [String: any StoreProductProviding] = [:]

        let resolved = ProductResolver.resolve(slots: slots, products: products, storeProducts: storeProducts)
        XCTAssertEqual(resolved[0].price, "$9.99")
        XCTAssertEqual(resolved[0].period, "month")
        XCTAssertEqual(resolved[0].periodLabel, "/mo")
    }

    // MARK: - Trial Period Formatting

    func testTrialPeriodFormatting_FreeTrial() {
        let slots = [makeSlot("primary", label: "Monthly", productId: "prod_monthly")]
        let products = [makeAWProduct(id: "prod_monthly", storeProductId: "com.app.monthly")]

        let storeProducts: [String: any StoreProductProviding] = [
            "com.app.monthly": MockStoreProduct(
                id: "com.app.monthly",
                displayPrice: "$9.99",
                price: Decimal(string: "9.99")!,
                subscriptionPeriodUnit: .month,
                subscriptionPeriodValue: 1,
                introOfferPaymentMode: .freeTrial,
                introOfferPeriodUnit: .day,
                introOfferPeriodValue: 7
            ),
        ]

        let resolved = ProductResolver.resolve(slots: slots, products: products, storeProducts: storeProducts)
        XCTAssertEqual(resolved[0].trialPeriod, "7 days")
        XCTAssertEqual(resolved[0].trialPrice, "Free")
    }

    func testTrialPeriodFormatting_PaidTrial() {
        let slots = [makeSlot("primary", label: "Monthly", productId: "prod_monthly")]
        let products = [makeAWProduct(id: "prod_monthly", storeProductId: "com.app.monthly")]

        let storeProducts: [String: any StoreProductProviding] = [
            "com.app.monthly": MockStoreProduct(
                id: "com.app.monthly",
                displayPrice: "$9.99",
                price: Decimal(string: "9.99")!,
                subscriptionPeriodUnit: .month,
                subscriptionPeriodValue: 1,
                introOfferPaymentMode: .payAsYouGo,
                introOfferPeriodUnit: .day,
                introOfferPeriodValue: 3,
                introOfferDisplayPrice: "$0.99"
            ),
        ]

        let resolved = ProductResolver.resolve(slots: slots, products: products, storeProducts: storeProducts)
        XCTAssertEqual(resolved[0].trialPeriod, "3 days")
        XCTAssertEqual(resolved[0].trialPrice, "$0.99")
    }

    func testNoTrialInfo_WhenNoIntroOffer() {
        let slots = [makeSlot("primary", label: "Monthly", productId: "prod_monthly")]
        let products = [makeAWProduct(id: "prod_monthly", storeProductId: "com.app.monthly")]

        let storeProducts: [String: any StoreProductProviding] = [
            "com.app.monthly": MockStoreProduct(
                id: "com.app.monthly",
                displayPrice: "$9.99",
                price: Decimal(string: "9.99")!,
                subscriptionPeriodUnit: .month,
                subscriptionPeriodValue: 1
            ),
        ]

        let resolved = ProductResolver.resolve(slots: slots, products: products, storeProducts: storeProducts)
        XCTAssertNil(resolved[0].trialPeriod)
        XCTAssertNil(resolved[0].trialPrice)
    }

    // MARK: - Period Label Formatting

    func testPeriodLabelFormatting() {
        XCTAssertEqual(ProductResolver.periodLabelString(unit: .month), "/mo")
        XCTAssertEqual(ProductResolver.periodLabelString(unit: .year), "/yr")
        XCTAssertEqual(ProductResolver.periodLabelString(unit: .week), "/wk")
        XCTAssertEqual(ProductResolver.periodLabelString(unit: .day), "/day")
    }

    func testPeriodLabelFromString() {
        XCTAssertEqual(ProductResolver.periodLabelFromString("month"), "/mo")
        XCTAssertEqual(ProductResolver.periodLabelFromString("year"), "/yr")
        XCTAssertEqual(ProductResolver.periodLabelFromString("week"), "/wk")
        XCTAssertEqual(ProductResolver.periodLabelFromString("day"), "/day")
    }

    // MARK: - Price Per Month

    func testPricePerMonthNormalization_Yearly() {
        let result = ProductResolver.calculatePricePerMonth(
            price: Decimal(string: "59.99")!,
            periodUnit: .year,
            periodValue: 1
        )
        XCTAssertNotNil(result)
        // $59.99 / 12 = $4.999... ≈ $5.00
        XCTAssertTrue(result!.contains("5.00") || result!.contains("4.99"), "Expected ~$5.00, got \(result!)")
    }

    func testPricePerMonthNormalization_Monthly() {
        let result = ProductResolver.calculatePricePerMonth(
            price: Decimal(string: "9.99")!,
            periodUnit: .month,
            periodValue: 1
        )
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("9.99"), "Expected $9.99, got \(result!)")
    }

    func testPricePerMonthNormalization_Weekly() {
        let result = ProductResolver.calculatePricePerMonth(
            price: Decimal(string: "2.99")!,
            periodUnit: .week,
            periodValue: 1
        )
        XCTAssertNotNil(result)
        // $2.99 * 4.33 ≈ $12.95
        XCTAssertTrue(result!.contains("12.9"), "Expected ~$12.95, got \(result!)")
    }

    // MARK: - Trial Period String Formatting

    func testFormatTrialPeriod_SingularDay() {
        XCTAssertEqual(ProductResolver.formatTrialPeriod(value: 1, unit: .day), "1 day")
    }

    func testFormatTrialPeriod_PluralDays() {
        XCTAssertEqual(ProductResolver.formatTrialPeriod(value: 7, unit: .day), "7 days")
    }

    func testFormatTrialPeriod_SingularMonth() {
        XCTAssertEqual(ProductResolver.formatTrialPeriod(value: 1, unit: .month), "1 month")
    }

    func testFormatTrialPeriod_PluralWeeks() {
        XCTAssertEqual(ProductResolver.formatTrialPeriod(value: 2, unit: .week), "2 weeks")
    }

    // MARK: - Edge Cases

    func testResolveWithEmptySlots() {
        let resolved = ProductResolver.resolve(slots: [], products: [], storeProducts: [:])
        XCTAssertTrue(resolved.isEmpty)
    }

    func testResolveWithNoMatchingAWProduct() {
        let slots = [makeSlot("primary", label: "Monthly", productId: "nonexistent")]
        let resolved = ProductResolver.resolve(slots: slots, products: [], storeProducts: [:])
        XCTAssertEqual(resolved.count, 1)
        XCTAssertEqual(resolved[0].price, "")
        XCTAssertEqual(resolved[0].slot, "primary")
    }

    func testResolveWithNilProductId() {
        let slots = [makeSlot("primary", label: "Monthly")]
        let resolved = ProductResolver.resolve(slots: slots, products: [], storeProducts: [:])
        XCTAssertEqual(resolved.count, 1)
        XCTAssertNil(resolved[0].productId)
    }

    func testStoreProductPriceAndPeriodLabel() {
        let slots = [makeSlot("primary", label: "Yearly", productId: "prod_yearly")]
        let products = [makeAWProduct(id: "prod_yearly", storeProductId: "com.app.yearly")]

        let storeProducts: [String: any StoreProductProviding] = [
            "com.app.yearly": MockStoreProduct(
                id: "com.app.yearly",
                displayPrice: "$59.99",
                price: Decimal(string: "59.99")!,
                subscriptionPeriodUnit: .year,
                subscriptionPeriodValue: 1
            ),
        ]

        let resolved = ProductResolver.resolve(slots: slots, products: products, storeProducts: storeProducts)
        XCTAssertEqual(resolved[0].price, "$59.99")
        XCTAssertEqual(resolved[0].period, "year")
        XCTAssertEqual(resolved[0].periodLabel, "/yr")
        XCTAssertEqual(resolved[0].rawPrice, Decimal(string: "59.99")!)
    }
}
