import Foundation

/// The compiled SDK config fetched from the API.
/// Contains all active campaigns, audiences, experiments, and paywall schemas.
public struct SDKConfig: Codable, Sendable {
    public let campaigns: [Campaign]
    public let paywalls: [String: PaywallSchema] // keyed by paywall ID
    public let products: [AWProduct]

    public init(campaigns: [Campaign], paywalls: [String: PaywallSchema], products: [AWProduct] = []) {
        self.campaigns = campaigns
        self.paywalls = paywalls
        self.products = products
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        campaigns = try container.decode([Campaign].self, forKey: .campaigns)
        paywalls = try container.decode([String: PaywallSchema].self, forKey: .paywalls)
        products = try container.decodeIfPresent([AWProduct].self, forKey: .products) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case campaigns, paywalls, products
    }
}
