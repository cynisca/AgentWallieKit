import Foundation
import SwiftUI

/// The subscription status of the current user.
public enum SubscriptionStatus: Sendable {
    case unknown
    case active
    case inactive
    case expired
}

/// Main entry point for the AgentWallie SDK.
@available(iOS 16.0, *)
public final class AgentWallie: @unchecked Sendable {

    // MARK: - Singleton

    public static let shared = AgentWallie()

    // MARK: - Public Properties

    /// Delegate for receiving SDK lifecycle events.
    public weak var delegate: AgentWallieDelegate?

    /// The current subscription status. Set this manually or let StoreKitManager update it.
    public var subscriptionStatus: SubscriptionStatus = .unknown

    /// The current set of active entitlements.
    public var entitlements: Set<String> = []

    // MARK: - Internal Properties

    private var apiKey: String?
    private var options: AgentWallieOptions?
    private var apiClient: APIClient?
    private var configManager: ConfigManager?
    private var userManager: UserManager?
    private var assignmentStore: AssignmentStore?
    private var presenter: PaywallPresenter?
    private var storeKitManager: StoreKitManager?
    private var purchaseController: PurchaseController?
    private var eventTracker: EventTracker?
    private var placementHandlers: [String: () -> Void] = [:]
    private var isConfigured = false
    private var currentPaywallSchema: PaywallSchema?
    private var currentPaywallId: String?
    private var currentCampaignId: String?

    private init() {}

    // MARK: - Configuration

    /// Configure the SDK with an API key and optional settings.
    public static func configure(apiKey: String, options: AgentWallieOptions = .init()) {
        shared.configureInternal(apiKey: apiKey, options: options)
    }

    private func configureInternal(apiKey: String, options: AgentWallieOptions) {
        guard !isConfigured else {
            log(.warn, "AgentWallie is already configured. Ignoring duplicate configure() call.")
            return
        }

        self.apiKey = apiKey
        self.options = options

        let baseURL = options.networkEnvironment.baseURL
        apiClient = APIClient(apiKey: apiKey, baseURL: baseURL)
        configManager = ConfigManager(apiClient: apiClient!)
        userManager = UserManager()
        assignmentStore = AssignmentStore()
        presenter = PaywallPresenter()
        storeKitManager = StoreKitManager()
        purchaseController = storeKitManager
        eventTracker = EventTracker(apiClient: apiClient!, userManager: userManager!)

        isConfigured = true

        // Fetch config on launch
        Task {
            do {
                try await configManager?.fetchConfig()
                configManager?.startAutoRefresh()
                log(.info, "Config fetched successfully.")
            } catch {
                log(.error, "Failed to fetch config: \(error)")
            }
        }
    }

    // MARK: - User Management

    /// Identify the current user.
    public func identify(userId: String) {
        ensureConfigured()
        userManager?.identify(userId: userId)
        log(.info, "Identified user: \(userId)")
    }

    /// Reset the current user — clears identity, attributes, and assignments.
    public func reset() {
        ensureConfigured()
        eventTracker?.flush()
        if let userId = userManager?.effectiveUserId {
            assignmentStore?.clearAssignments(userId: userId)
        }
        userManager?.reset()
        entitlements = []
        subscriptionStatus = .unknown
        log(.info, "User reset.")
    }

    /// Set user attributes for audience targeting.
    public func setUserAttributes(_ attributes: [String: Any]) {
        ensureConfigured()
        userManager?.setAttributes(attributes)
    }

    // MARK: - Event Tracking

    /// Track a custom event.
    public func trackEvent(name: String, properties: [String: Any]? = nil) {
        ensureConfigured()
        eventTracker?.track(name: name, properties: properties)
    }

    // MARK: - Placements

    /// Register a placement. If the user matches a campaign audience, the paywall is presented.
    /// The handler closure runs if the user has the required entitlement (no paywall needed).
    public func register(placement: String, handler: (() -> Void)? = nil) {
        ensureConfigured()
        placementHandlers[placement] = handler

        guard let config = configManager?.config,
              let userMgr = userManager,
              let store = assignmentStore else {
            log(.warn, "Config not ready. Placement '\(placement)' will not evaluate.")
            handler?()
            return
        }

        let context = userMgr.buildContext()

        let result = PlacementEvaluator.evaluate(
            placement: placement,
            config: config,
            context: context,
            userId: userMgr.effectiveUserId,
            entitlements: entitlements,
            assignmentStore: store
        )

        guard let result = result else {
            // No campaign matched — run the handler (feature gate passes)
            handler?()
            return
        }

        if result.isHoldout {
            // Holdout — run the handler
            handler?()
            return
        }

        guard let paywallId = result.paywallId,
              let schema = config.paywalls[paywallId] else {
            handler?()
            return
        }

        // Present the paywall
        Task { @MainActor in
            self.presentPaywallSchema(
                schema,
                paywallId: paywallId,
                campaignId: result.campaignId,
                audienceId: result.audienceId,
                experimentId: result.experimentId,
                variantId: result.variantId
            )
        }
    }

    // MARK: - Programmatic Presentation

    /// Present a paywall by its ID (bypasses campaign logic).
    public func presentPaywall(id: String) {
        ensureConfigured()
        guard let config = configManager?.config,
              let schema = config.paywalls[id] else {
            log(.warn, "Paywall '\(id)' not found in config.")
            return
        }

        Task { @MainActor in
            self.presentPaywallSchema(schema, paywallId: id)
        }
    }

    /// Get a paywall schema for a placement without presenting it.
    public func getPaywall(forPlacement placement: String, completion: @escaping (Result<PaywallSchema, Error>) -> Void) {
        ensureConfigured()
        guard let config = configManager?.config,
              let userMgr = userManager,
              let store = assignmentStore else {
            completion(.failure(AgentWallieError.notConfigured))
            return
        }

        let context = userMgr.buildContext()

        let result = PlacementEvaluator.evaluate(
            placement: placement,
            config: config,
            context: context,
            userId: userMgr.effectiveUserId,
            entitlements: entitlements,
            assignmentStore: store
        )

        guard let result = result,
              !result.isHoldout,
              let paywallId = result.paywallId,
              let schema = config.paywalls[paywallId] else {
            completion(.failure(AgentWallieError.noPaywallFound))
            return
        }

        completion(.success(schema))
    }

    // MARK: - Deep Links

    /// Handle a deep link URL.
    public func handleDeepLink(_ url: URL) {
        ensureConfigured()
        // Extract paywall ID from deep link if present
        // Format: agentwallie://paywall/{id}
        guard url.scheme == "agentwallie",
              url.host == "paywall",
              let paywallId = url.pathComponents.dropFirst().first else {
            log(.info, "Deep link not handled: \(url)")
            return
        }

        presentPaywall(id: paywallId)
    }

    // MARK: - Private

    @MainActor
    private func presentPaywallSchema(
        _ schema: PaywallSchema,
        paywallId: String? = nil,
        campaignId: String? = nil,
        audienceId: String? = nil,
        experimentId: String? = nil,
        variantId: String? = nil
    ) {
        self.currentPaywallSchema = schema
        self.currentPaywallId = paywallId
        self.currentCampaignId = campaignId

        let info = PaywallPresentationInfo(
            paywallId: paywallId,
            paywallName: schema.name,
            campaignId: campaignId,
            audienceId: audienceId,
            experimentId: experimentId,
            variantId: variantId
        )

        eventTracker?.track(
            name: "paywall_open",
            campaignId: campaignId,
            paywallId: paywallId
        )

        delegate?.didPresentPaywall(info: info)

        presenter?.present(
            schema: schema,
            onAction: { [weak self] action, param in
                self?.handlePaywallAction(action, param: param)
            },
            onDismiss: { [weak self] in
                self?.delegate?.didDismissPaywall(info: info)
            }
        )
    }

    private func handlePaywallAction(_ action: TapBehavior, param: String?) {
        switch action {
        case .purchase:
            guard let slotName = param else { return }

            // Resolve the slot name to a store product ID
            guard let storeProductId = resolveStoreProductId(slotName: slotName) else {
                log(.warn, "Could not resolve product for slot '\(slotName)'. Check paywall products and config.products.")
                return
            }

            eventTracker?.track(
                name: "purchase_started",
                properties: ["slot": slotName, "store_product_id": storeProductId],
                campaignId: currentCampaignId,
                paywallId: currentPaywallId
            )

            Task {
                do {
                    let result = try await purchaseController?.purchase(productId: storeProductId)
                    if case .purchased = result {
                        eventTracker?.track(
                            name: "transaction_complete",
                            properties: ["slot": slotName, "store_product_id": storeProductId],
                            campaignId: currentCampaignId,
                            paywallId: currentPaywallId
                        )
                        delegate?.didCompletePurchase(productId: storeProductId)
                    }
                } catch {
                    log(.error, "Purchase failed: \(error)")
                }
            }

        case .restore:
            eventTracker?.track(
                name: "restore_started",
                campaignId: currentCampaignId,
                paywallId: currentPaywallId
            )

            Task {
                do {
                    let result = try await purchaseController?.restorePurchases()
                    if case .restored = result {
                        delegate?.didRestorePurchases()
                    }
                } catch {
                    log(.error, "Restore failed: \(error)")
                }
            }

        case .openUrl:
            if let urlString = param, let url = URL(string: urlString) {
                #if canImport(UIKit)
                Task { @MainActor in
                    UIApplication.shared.open(url)
                }
                #endif
            }

        case .customAction:
            if let name = param {
                delegate?.handleCustomAction(name: name)
            }

        case .close:
            eventTracker?.track(
                name: "paywall_close",
                campaignId: currentCampaignId,
                paywallId: currentPaywallId
            )

        default:
            break
        }
    }

    /// Resolve a slot name (e.g., "primary") to an App Store product ID.
    private func resolveStoreProductId(slotName: String) -> String? {
        // 1. Find the slot in the current paywall's products array
        guard let slot = currentPaywallSchema?.products?.first(where: { $0.slot == slotName }) else {
            log(.warn, "No product slot named '\(slotName)' in current paywall.")
            return nil
        }

        // 2. Look up the product by its productId in config.products
        guard let productId = slot.productId,
              let config = configManager?.config,
              let product = config.products.first(where: { $0.id == productId }) else {
            // Fallback: try matching slot name directly against config products
            if let config = configManager?.config,
               let product = config.products.first(where: { $0.id == slotName }) {
                return product.storeProductId
            }
            log(.warn, "No product found for slot '\(slotName)' with productId '\(slot.productId ?? "nil")'.")
            return nil
        }

        return product.storeProductId
    }

    private func ensureConfigured() {
        if !isConfigured {
            log(.error, "AgentWallie.configure() must be called before using the SDK.")
        }
    }

    private func log(_ level: LogLevel, _ message: String) {
        guard let options = options, level >= options.logLevel else { return }
        delegate?.handleLog(level: level, message: message)
        #if DEBUG
        print("[AgentWallie] [\(level)] \(message)")
        #endif
    }
}

// MARK: - Errors

public enum AgentWallieError: Error, Sendable {
    case notConfigured
    case noPaywallFound
    case configFetchFailed
}
