import Foundation

/// Delegate protocol for receiving SDK lifecycle events.
public protocol AgentWallieDelegate: AnyObject {
    /// Called when a paywall is presented.
    func didPresentPaywall(info: PaywallPresentationInfo)

    /// Called when a paywall is dismissed.
    func didDismissPaywall(info: PaywallPresentationInfo)

    /// Called when a purchase completes successfully.
    func didCompletePurchase(productId: String)

    /// Called when a purchase fails.
    func didFailPurchase(productId: String, error: Error)

    /// Called when purchases are restored.
    func didRestorePurchases()

    /// Called when a custom action is triggered from a paywall.
    func handleCustomAction(name: String)

    /// Called for SDK log events.
    func handleLog(level: LogLevel, message: String)

    /// Called when subscription status or entitlements change.
    func didUpdateSubscriptionStatus(_ status: SubscriptionStatus, entitlements: Set<String>)
}

/// Default implementations so delegates only need to implement what they care about.
public extension AgentWallieDelegate {
    func didPresentPaywall(info: PaywallPresentationInfo) {}
    func didDismissPaywall(info: PaywallPresentationInfo) {}
    func didCompletePurchase(productId: String) {}
    func didFailPurchase(productId: String, error: Error) {}
    func didRestorePurchases() {}
    func handleCustomAction(name: String) {}
    func handleLog(level: LogLevel, message: String) {}
    func didUpdateSubscriptionStatus(_ status: SubscriptionStatus, entitlements: Set<String>) {}
}

/// Information about a paywall presentation.
public struct PaywallPresentationInfo: Sendable {
    public let paywallId: String?
    public let paywallName: String
    public let campaignId: String?
    public let audienceId: String?
    public let experimentId: String?
    public let variantId: String?

    public init(
        paywallId: String? = nil,
        paywallName: String,
        campaignId: String? = nil,
        audienceId: String? = nil,
        experimentId: String? = nil,
        variantId: String? = nil
    ) {
        self.paywallId = paywallId
        self.paywallName = paywallName
        self.campaignId = campaignId
        self.audienceId = audienceId
        self.experimentId = experimentId
        self.variantId = variantId
    }
}
