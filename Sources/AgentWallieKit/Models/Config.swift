import Foundation

/// The compiled SDK config fetched from the API.
/// Contains all active campaigns, audiences, experiments, and paywall schemas.
public struct SDKConfig: Codable, Sendable {
    public let campaigns: [Campaign]
    public let paywalls: [String: PaywallSchema] // keyed by paywall ID

    public init(campaigns: [Campaign], paywalls: [String: PaywallSchema]) {
        self.campaigns = campaigns
        self.paywalls = paywalls
    }
}
