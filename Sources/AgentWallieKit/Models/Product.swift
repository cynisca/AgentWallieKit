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
