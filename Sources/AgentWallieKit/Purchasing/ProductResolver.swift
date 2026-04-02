import Foundation
import StoreKit

/// Protocol abstracting StoreKit product data for testability.
/// StoreKit.Product cannot be instantiated in unit tests, so ProductResolver
/// works against this protocol instead.
@available(iOS 16.0, *)
public protocol StoreProductProviding: Sendable {
    var id: String { get }
    var displayPrice: String { get }
    var price: Decimal { get }
    var subscriptionPeriodUnit: ProductResolver.PeriodUnit? { get }
    var subscriptionPeriodValue: Int? { get }
    var introOfferPaymentMode: ProductResolver.IntroPaymentMode? { get }
    var introOfferPeriodUnit: ProductResolver.PeriodUnit? { get }
    var introOfferPeriodValue: Int? { get }
    var introOfferDisplayPrice: String? { get }
}

/// Resolves product slots + dashboard products + StoreKit data into display-ready ResolvedProductInfo.
@available(iOS 16.0, *)
public struct ProductResolver {

    /// Subscription period unit, mirroring StoreKit's representation.
    public enum PeriodUnit: Sendable {
        case day, week, month, year
    }

    /// Introductory offer payment mode.
    public enum IntroPaymentMode: Sendable {
        case freeTrial, payAsYouGo, payUpFront
    }

    /// Reusable currency formatter (NumberFormatter is expensive to create).
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// Approximate number of weeks per month, used for weekly-to-monthly conversion.
    private static let weeksPerMonth = Decimal(string: "4.33")!

    /// Resolve an array of paywall product slots into display-ready product info.
    ///
    /// - Parameters:
    ///   - slots: The product slots from the paywall schema.
    ///   - products: The dashboard-configured products (AWProduct) from SDKConfig.
    ///   - storeProducts: A dictionary of StoreKit product data keyed by store product ID.
    /// - Returns: An array of ResolvedProductInfo, one per slot.
    public static func resolve(
        slots: [ProductSlot],
        products: [AWProduct],
        storeProducts: [String: any StoreProductProviding]
    ) -> [ResolvedProductInfo] {
        // First pass: resolve each slot
        var resolved = slots.map { slot -> ResolvedProductInfo in
            resolveSingle(slot: slot, products: products, storeProducts: storeProducts)
        }

        // Second pass: calculate savings relative to the monthly product
        let monthlyPricePerMonth = findMonthlyPrice(in: resolved)
        if let monthly = monthlyPricePerMonth {
            for i in resolved.indices {
                resolved[i].savingsPercentage = calculateSavings(
                    rawMonthlyPrice: resolved[i].rawMonthlyPrice,
                    period: resolved[i].period,
                    monthlyPrice: monthly
                )
            }
        }

        return resolved
    }

    // MARK: - Single Slot Resolution

    private static func resolveSingle(
        slot: ProductSlot,
        products: [AWProduct],
        storeProducts: [String: any StoreProductProviding]
    ) -> ResolvedProductInfo {
        // Find the AWProduct for this slot (match by UUID or store product ID)
        let awProduct = slot.productId.flatMap { pid in
            products.first(where: { $0.id == pid })
                ?? products.first(where: { $0.storeProductId == pid })
        }

        // Find the StoreKit product if available
        let storeProduct: (any StoreProductProviding)? = awProduct.flatMap { aw in
            storeProducts[aw.storeProductId]
        }

        if let sp = storeProduct {
            return resolveFromStoreProduct(slot: slot, awProduct: awProduct, storeProduct: sp)
        } else {
            return resolveFromFallback(slot: slot, awProduct: awProduct)
        }
    }

    private static func resolveFromStoreProduct(
        slot: ProductSlot,
        awProduct: AWProduct?,
        storeProduct: any StoreProductProviding
    ) -> ResolvedProductInfo {
        // Prefer the server-configured displayPeriod over StoreKit's period unit.
        // In sandbox, Apple reports weekly subscriptions as .day (accelerated time),
        // which causes the paywall to show "/day" instead of "/wk".
        let periodUnit: PeriodUnit
        if let serverPeriod = awProduct?.displayPeriod, let parsed = periodUnitFromString(serverPeriod) {
            periodUnit = parsed
        } else {
            periodUnit = storeProduct.subscriptionPeriodUnit ?? .month
        }
        let periodValue = storeProduct.subscriptionPeriodValue ?? 1
        let period = periodString(unit: periodUnit)
        let periodLabel = periodLabelString(unit: periodUnit)

        let monthlyResult = calculatePricePerMonth(
            price: storeProduct.price,
            periodUnit: periodUnit,
            periodValue: periodValue
        )

        let (trialPeriod, trialPrice) = resolveTrialInfo(storeProduct: storeProduct)

        return ResolvedProductInfo(
            slot: slot.slot,
            label: slot.label,
            productId: slot.productId,
            storeProductId: awProduct?.storeProductId,
            price: storeProduct.displayPrice,
            pricePerMonth: monthlyResult.formatted,
            period: period,
            periodLabel: periodLabel,
            trialPeriod: trialPeriod,
            trialPrice: trialPrice,
            rawPrice: storeProduct.price,
            rawMonthlyPrice: monthlyResult.raw
        )
    }

    private static func resolveFromFallback(
        slot: ProductSlot,
        awProduct: AWProduct?
    ) -> ResolvedProductInfo {
        let price = awProduct?.displayPrice ?? ""
        let period = awProduct?.displayPeriod ?? "month"
        let periodLabel = periodLabelFromString(period)

        return ResolvedProductInfo(
            slot: slot.slot,
            label: slot.label,
            productId: slot.productId,
            storeProductId: awProduct?.storeProductId,
            price: price,
            period: period,
            periodLabel: periodLabel
        )
    }

    // MARK: - Trial Info

    private static func resolveTrialInfo(
        storeProduct: any StoreProductProviding
    ) -> (trialPeriod: String?, trialPrice: String?) {
        guard let periodUnit = storeProduct.introOfferPeriodUnit,
              let periodValue = storeProduct.introOfferPeriodValue else {
            return (nil, nil)
        }

        let periodStr = formatTrialPeriod(value: periodValue, unit: periodUnit)

        let priceStr: String
        if let paymentMode = storeProduct.introOfferPaymentMode {
            switch paymentMode {
            case .freeTrial:
                priceStr = "Free"
            case .payAsYouGo, .payUpFront:
                priceStr = storeProduct.introOfferDisplayPrice ?? ""
            }
        } else {
            priceStr = "Free"
        }

        return (periodStr, priceStr)
    }

    // MARK: - Period Formatting

    /// Convert a PeriodUnit to a human-readable string.
    public static func periodString(unit: PeriodUnit) -> String {
        switch unit {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        }
    }

    /// Convert a PeriodUnit to a short label like "/mo".
    public static func periodLabelString(unit: PeriodUnit) -> String {
        switch unit {
        case .day: return "/day"
        case .week: return "/wk"
        case .month: return "/mo"
        case .year: return "/yr"
        }
    }

    /// Parse a period string ("day", "week", "month", "year") into a PeriodUnit.
    public static func periodUnitFromString(_ period: String) -> PeriodUnit? {
        switch period.lowercased() {
        case "day": return .day
        case "week": return .week
        case "month": return .month
        case "year": return .year
        default: return nil
        }
    }

    /// Convert a period string ("month", "year") to a short label.
    public static func periodLabelFromString(_ period: String) -> String {
        switch period.lowercased() {
        case "day": return "/day"
        case "week": return "/wk"
        case "month": return "/mo"
        case "year": return "/yr"
        default: return "/\(period)"
        }
    }

    /// Format a trial period into a human-readable string like "7 days" or "1 month".
    public static func formatTrialPeriod(value: Int, unit: PeriodUnit) -> String {
        let unitStr: String
        switch unit {
        case .day: unitStr = value == 1 ? "day" : "days"
        case .week: unitStr = value == 1 ? "week" : "weeks"
        case .month: unitStr = value == 1 ? "month" : "months"
        case .year: unitStr = value == 1 ? "year" : "years"
        }
        return "\(value) \(unitStr)"
    }

    // MARK: - Price Calculations

    /// Calculate the normalized monthly price, returning both formatted string and raw Decimal.
    public static func calculatePricePerMonth(
        price: Decimal,
        periodUnit: PeriodUnit,
        periodValue: Int
    ) -> (formatted: String?, raw: Decimal) {
        let monthlyPrice: Decimal
        switch periodUnit {
        case .day:
            // Convert daily to monthly (approximate: 30 days)
            monthlyPrice = (price / Decimal(periodValue)) * 30
        case .week:
            // Convert weekly to monthly (approximate: 4.33 weeks)
            monthlyPrice = (price / Decimal(periodValue)) * weeksPerMonth
        case .month:
            monthlyPrice = price / Decimal(periodValue)
        case .year:
            // Convert yearly to monthly
            monthlyPrice = price / (Decimal(periodValue) * 12)
        }

        let formatted = currencyFormatter.string(from: monthlyPrice as NSDecimalNumber)
        return (formatted, monthlyPrice)
    }

    /// Calculate savings percentage relative to the monthly price.
    /// Returns nil if the product IS the monthly product or if monthly price is unavailable.
    private static func calculateSavings(
        rawMonthlyPrice: Decimal?,
        period: String,
        monthlyPrice: Decimal
    ) -> Int? {
        guard period != "month" else { return nil }
        guard let perMonth = rawMonthlyPrice else { return nil }
        guard monthlyPrice > 0 else { return nil }

        var savings = ((monthlyPrice - perMonth) / monthlyPrice) * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &savings, 0, .plain)
        let intValue = NSDecimalNumber(decimal: rounded).intValue
        return intValue > 0 ? intValue : nil
    }

    /// Find the monthly product's raw price from resolved products.
    private static func findMonthlyPrice(in products: [ResolvedProductInfo]) -> Decimal? {
        products.first(where: { $0.period == "month" })?.rawPrice
    }
}

// MARK: - StoreKit.Product Conformance

@available(iOS 16.0, *)
extension StoreKit.Product: StoreProductProviding {
    public var subscriptionPeriodUnit: ProductResolver.PeriodUnit? {
        guard let period = subscription?.subscriptionPeriod else { return nil }
        switch period.unit {
        case .day: return .day
        case .week: return .week
        case .month: return .month
        case .year: return .year
        @unknown default: return .month
        }
    }

    public var subscriptionPeriodValue: Int? {
        subscription?.subscriptionPeriod.value
    }

    public var introOfferPaymentMode: ProductResolver.IntroPaymentMode? {
        guard let offer = subscription?.introductoryOffer else { return nil }
        switch offer.paymentMode {
        case .freeTrial: return .freeTrial
        case .payAsYouGo: return .payAsYouGo
        case .payUpFront: return .payUpFront
        default: return .freeTrial
        }
    }

    public var introOfferPeriodUnit: ProductResolver.PeriodUnit? {
        guard let period = subscription?.introductoryOffer?.period else { return nil }
        switch period.unit {
        case .day: return .day
        case .week: return .week
        case .month: return .month
        case .year: return .year
        @unknown default: return .month
        }
    }

    public var introOfferPeriodValue: Int? {
        subscription?.introductoryOffer?.period.value
    }

    public var introOfferDisplayPrice: String? {
        subscription?.introductoryOffer?.displayPrice
    }
}
