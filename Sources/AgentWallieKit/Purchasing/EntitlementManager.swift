import StoreKit

/// Manages entitlement state derived from StoreKit transactions and config product mappings.
@available(iOS 16.0, *)
public final class EntitlementManager: @unchecked Sendable {
    private let lock = NSLock()
    private var _activeEntitlements: Set<String> = []
    private var _subscriptionStatus: SubscriptionStatus = .unknown

    /// The product-to-entitlement mapping from config
    private var productEntitlements: [String: [String]] = [:]  // storeProductId -> entitlements

    public var activeEntitlements: Set<String> {
        lock.lock(); defer { lock.unlock() }
        return _activeEntitlements
    }

    public var subscriptionStatus: SubscriptionStatus {
        lock.lock(); defer { lock.unlock() }
        return _subscriptionStatus
    }

    public init() {}

    /// Update the product-to-entitlement mapping from config products.
    public func updateProductMapping(products: [AWProduct]) {
        lock.lock(); defer { lock.unlock() }
        productEntitlements.removeAll()
        for product in products {
            if !product.entitlements.isEmpty {
                productEntitlements[product.storeProductId] = product.entitlements
            }
        }
    }

    /// Refresh entitlements by checking StoreKit's current entitlements.
    public func refreshFromStoreKit() async {
        var newEntitlements: Set<String> = []
        var hasActive = false

        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            hasActive = true

            lock.lock()
            let entitlements = productEntitlements[transaction.productID] ?? []
            lock.unlock()

            newEntitlements.formUnion(entitlements)
        }

        lock.lock()
        _activeEntitlements = newEntitlements
        _subscriptionStatus = hasActive ? .active : .inactive
        lock.unlock()
    }

    /// Handle a completed purchase — add entitlements for the purchased product.
    public func handlePurchase(storeProductId: String) {
        lock.lock()
        if let entitlements = productEntitlements[storeProductId] {
            _activeEntitlements.formUnion(entitlements)
            _subscriptionStatus = .active
        }
        lock.unlock()
    }

    /// Handle a restored purchase.
    public func handleRestore(storeProductIds: [String]) {
        lock.lock()
        for id in storeProductIds {
            if let entitlements = productEntitlements[id] {
                _activeEntitlements.formUnion(entitlements)
            }
        }
        if !_activeEntitlements.isEmpty {
            _subscriptionStatus = .active
        }
        lock.unlock()
    }

    /// Reset all entitlements (on user reset).
    public func reset() {
        lock.lock()
        _activeEntitlements.removeAll()
        _subscriptionStatus = .unknown
        lock.unlock()
    }

    /// Look up entitlements for a product ID.
    public func entitlements(for storeProductId: String) -> [String] {
        lock.lock(); defer { lock.unlock() }
        return productEntitlements[storeProductId] ?? []
    }
}
