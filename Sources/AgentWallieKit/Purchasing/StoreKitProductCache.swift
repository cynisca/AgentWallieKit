import StoreKit

/// Actor-based cache for StoreKit.Product objects.
/// Fetches products from the App Store and caches them for fast lookup during paywall rendering.
@available(iOS 16.0, *)
public actor StoreKitProductCache {
    private var products: [String: StoreKit.Product] = [:]

    public init() {}

    /// Fetch and cache StoreKit products for the given product IDs.
    /// Products already in cache are overwritten with fresh data.
    public func prefetch(productIds: Set<String>) async throws {
        guard !productIds.isEmpty else { return }
        let fetched = try await StoreKit.Product.products(for: productIds)
        for product in fetched {
            products[product.id] = product
        }
    }

    /// Look up a cached product by its App Store product ID.
    public func product(for id: String) -> StoreKit.Product? {
        products[id]
    }

    /// Return all cached products keyed by product ID.
    public func allProducts() -> [String: StoreKit.Product] {
        products
    }

    /// Remove all cached products.
    public func clear() {
        products.removeAll()
    }
}
