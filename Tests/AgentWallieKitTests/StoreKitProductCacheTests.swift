import XCTest
@testable import AgentWallieKit

/// Tests for StoreKitProductCache logic.
/// Since StoreKit.Product cannot be instantiated in unit tests,
/// these tests verify the cache data structure behavior using a
/// mock actor that mirrors the real cache's API.
@available(iOS 16.0, *)
final class StoreKitProductCacheTests: XCTestCase {

    // MARK: - MockProductCache (mirrors actor behavior for testing)

    actor MockProductCache {
        private var products: [String: MockStoreProduct] = [:]

        func store(_ product: MockStoreProduct) {
            products[product.id] = product
        }

        func product(for id: String) -> MockStoreProduct? {
            products[id]
        }

        func allProducts() -> [String: MockStoreProduct] {
            products
        }

        func clear() {
            products.removeAll()
        }

        func prefetch(_ mockProducts: [MockStoreProduct]) {
            for product in mockProducts {
                products[product.id] = product
            }
        }
    }

    // MARK: - Tests

    func testCacheStoresAndRetrievesProducts() async {
        let cache = MockProductCache()
        let product = MockStoreProduct(
            id: "com.app.monthly",
            displayPrice: "$9.99",
            price: Decimal(string: "9.99")!
        )

        await cache.store(product)
        let retrieved = await cache.product(for: "com.app.monthly")
        XCTAssertEqual(retrieved?.id, "com.app.monthly")
        XCTAssertEqual(retrieved?.displayPrice, "$9.99")
    }

    func testCacheMissReturnsNil() async {
        let cache = MockProductCache()
        let result = await cache.product(for: "nonexistent")
        let isNil = result == nil
        XCTAssertTrue(isNil)
    }

    func testClearEmptiesCache() async {
        let cache = MockProductCache()
        let product = MockStoreProduct(
            id: "com.app.yearly",
            displayPrice: "$59.99",
            price: Decimal(string: "59.99")!
        )

        await cache.store(product)
        let beforeClear = await cache.product(for: "com.app.yearly")
        XCTAssertEqual(beforeClear?.id, "com.app.yearly")

        await cache.clear()
        let afterClear = await cache.product(for: "com.app.yearly")
        let isNil = afterClear == nil
        XCTAssertTrue(isNil)

        let all = await cache.allProducts()
        XCTAssertTrue(all.isEmpty)
    }

    func testPrefetchWithEmptySetDoesNotCrash() async {
        let cache = MockProductCache()
        await cache.prefetch([])
        let all = await cache.allProducts()
        XCTAssertTrue(all.isEmpty)
    }

    func testPrefetchMultipleProducts() async {
        let cache = MockProductCache()
        let products = [
            MockStoreProduct(id: "com.app.monthly", displayPrice: "$9.99", price: Decimal(string: "9.99")!),
            MockStoreProduct(id: "com.app.yearly", displayPrice: "$59.99", price: Decimal(string: "59.99")!),
        ]

        await cache.prefetch(products)
        let all = await cache.allProducts()
        XCTAssertEqual(all.count, 2)

        let monthly = await cache.product(for: "com.app.monthly")
        XCTAssertEqual(monthly?.id, "com.app.monthly")

        let yearly = await cache.product(for: "com.app.yearly")
        XCTAssertEqual(yearly?.id, "com.app.yearly")
    }

    func testPrefetchOverwritesExistingProduct() async {
        let cache = MockProductCache()
        let original = MockStoreProduct(id: "com.app.monthly", displayPrice: "$9.99", price: Decimal(string: "9.99")!)
        let updated = MockStoreProduct(id: "com.app.monthly", displayPrice: "$7.99", price: Decimal(string: "7.99")!)

        await cache.store(original)
        await cache.prefetch([updated])

        let retrieved = await cache.product(for: "com.app.monthly")
        XCTAssertEqual(retrieved?.displayPrice, "$7.99")
    }
}
