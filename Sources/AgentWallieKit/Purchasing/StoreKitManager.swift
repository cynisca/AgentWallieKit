import StoreKit

/// Default StoreKit 2 integration for handling purchases.
@available(iOS 16.0, *)
public final class StoreKitManager: PurchaseController, @unchecked Sendable {
    private var transactionListener: Task<Void, Never>?

    /// Callback when a subscription status changes.
    public var onTransactionUpdate: ((StoreKit.Transaction) -> Void)?

    public init() {
        startTransactionListener()
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - PurchaseController

    public func purchase(productId: String) async throws -> PurchaseResult {
        let products = try await StoreKit.Product.products(for: [productId])
        guard let product = products.first else {
            throw StoreKitError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return .purchased

        case .userCancelled:
            return .cancelled

        case .pending:
            return .pending

        @unknown default:
            return .failed(StoreKitError.unknownResult)
        }
    }

    public func restorePurchases() async throws -> RestorationResult {
        try await AppStore.sync()

        var hasRestoredProducts = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                _ = transaction
                hasRestoredProducts = true
            }
        }

        return hasRestoredProducts ? .restored : .noProductsToRestore
    }

    // MARK: - Transaction Listening

    private func startTransactionListener() {
        transactionListener = Task.detached { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self = self else { break }
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                    self.onTransactionUpdate?(transaction)
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}

/// StoreKit-related errors.
public enum StoreKitError: Error, Sendable {
    case productNotFound
    case unknownResult
    case verificationFailed
}
