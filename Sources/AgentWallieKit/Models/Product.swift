import Foundation

/// Store type for the product.
public enum StoreType: String, Codable, Sendable {
    case apple
    case google
    case stripe
}

/// A product configured in the AgentWallie dashboard.
public struct AWProduct: Codable, Sendable {
    public let id: String
    public let name: String
    public let store: StoreType
    public let storeProductId: String
    public let entitlements: [String]
    public let basePlanId: String?
    public let offerIds: [String]?
    public let displayPrice: String?
    public let displayPeriod: String?

    public init(
        id: String,
        name: String,
        store: StoreType,
        storeProductId: String,
        entitlements: [String],
        basePlanId: String? = nil,
        offerIds: [String]? = nil,
        displayPrice: String? = nil,
        displayPeriod: String? = nil
    ) {
        self.id = id
        self.name = name
        self.store = store
        self.storeProductId = storeProductId
        self.entitlements = entitlements
        self.basePlanId = basePlanId
        self.offerIds = offerIds
        self.displayPrice = displayPrice
        self.displayPeriod = displayPeriod
    }

    enum CodingKeys: String, CodingKey {
        case id, name, store, entitlements
        case storeProductId = "store_product_id"
        case basePlanId = "base_plan_id"
        case offerIds = "offer_ids"
        case displayPrice = "display_price"
        case displayPeriod = "display_period"
    }
}

/// A product slot in a paywall schema — maps abstract names like "primary" to real products.
public struct ProductSlot: Codable, Sendable {
    public let slot: String
    public let label: String
    public let productId: String?

    public init(slot: String, label: String, productId: String? = nil) {
        self.slot = slot
        self.label = label
        self.productId = productId
    }

    enum CodingKeys: String, CodingKey {
        case slot, label
        case productId = "product_id"
    }
}

/// Resolved product information combining paywall slot data, dashboard product config,
/// and live StoreKit pricing. Used at render time to display real prices in paywalls.
public struct ResolvedProductInfo: Sendable {
    public let slot: String
    public let label: String
    public let productId: String?
    public let storeProductId: String?

    /// Localized display price, e.g. "$4.99"
    public var price: String

    /// Normalized monthly price, e.g. "$3.33" for a yearly product
    public var pricePerMonth: String?

    /// Subscription period unit: "day", "week", "month", "year"
    public var period: String

    /// Short period label for display: "/mo", "/yr", "/wk"
    public var periodLabel: String

    /// Trial duration description, e.g. "7 days", "3 days"
    public var trialPeriod: String?

    /// Trial price, e.g. "Free" or "$0.99"
    public var trialPrice: String?

    /// Savings percentage relative to monthly pricing, e.g. 50
    public var savingsPercentage: Int?

    /// Raw decimal price for calculations
    public var rawPrice: Decimal?

    public init(
        slot: String,
        label: String,
        productId: String? = nil,
        storeProductId: String? = nil,
        price: String,
        pricePerMonth: String? = nil,
        period: String,
        periodLabel: String,
        trialPeriod: String? = nil,
        trialPrice: String? = nil,
        savingsPercentage: Int? = nil,
        rawPrice: Decimal? = nil
    ) {
        self.slot = slot
        self.label = label
        self.productId = productId
        self.storeProductId = storeProductId
        self.price = price
        self.pricePerMonth = pricePerMonth
        self.period = period
        self.periodLabel = periodLabel
        self.trialPeriod = trialPeriod
        self.trialPrice = trialPrice
        self.savingsPercentage = savingsPercentage
        self.rawPrice = rawPrice
    }
}
