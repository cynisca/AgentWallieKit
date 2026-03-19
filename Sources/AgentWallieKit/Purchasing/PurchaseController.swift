import StoreKit

/// Protocol for custom purchase handling (e.g., RevenueCat integration).
/// If not provided, the SDK uses StoreKitManager for direct StoreKit 2 purchases.
@available(iOS 16.0, *)
public protocol PurchaseController: AnyObject, Sendable {
    /// Purchase a product by its App Store product ID.
    func purchase(productId: String) async throws -> PurchaseResult

    /// Restore previous purchases.
    func restorePurchases() async throws -> RestorationResult
}

/// The result of a purchase attempt.
public enum PurchaseResult: Sendable {
    case purchased
    case cancelled
    case pending
    case failed(Error)
}

/// The result of a restoration attempt.
public enum RestorationResult: Sendable {
    case restored
    case noProductsToRestore
    case failed(Error)
}
