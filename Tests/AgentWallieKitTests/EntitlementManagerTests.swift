import XCTest
@testable import AgentWallieKit

@available(iOS 16.0, *)
final class EntitlementManagerTests: XCTestCase {

    // MARK: - Helpers

    private func makeProduct(
        id: String = "prod_1",
        storeProductId: String = "com.app.monthly",
        entitlements: [String] = ["premium"]
    ) -> AWProduct {
        AWProduct(
            id: id,
            name: "Test Product",
            store: .apple,
            storeProductId: storeProductId,
            entitlements: entitlements
        )
    }

    // MARK: - Tests

    func testInitialState() {
        let manager = EntitlementManager()
        XCTAssertEqual(manager.subscriptionStatus, .unknown)
        XCTAssertTrue(manager.activeEntitlements.isEmpty)
    }

    func testUpdateProductMapping() {
        let manager = EntitlementManager()
        let products = [
            makeProduct(id: "p1", storeProductId: "com.app.monthly", entitlements: ["premium"]),
            makeProduct(id: "p2", storeProductId: "com.app.yearly", entitlements: ["premium", "vip"]),
        ]
        manager.updateProductMapping(products: products)

        XCTAssertEqual(manager.entitlements(for: "com.app.monthly"), ["premium"])
        XCTAssertEqual(Set(manager.entitlements(for: "com.app.yearly")), Set(["premium", "vip"]))
    }

    func testHandlePurchase() {
        let manager = EntitlementManager()
        manager.updateProductMapping(products: [
            makeProduct(storeProductId: "com.app.monthly", entitlements: ["premium", "analytics"]),
        ])

        manager.handlePurchase(storeProductId: "com.app.monthly")

        XCTAssertEqual(manager.activeEntitlements, Set(["premium", "analytics"]))
    }

    func testHandlePurchaseUnknownProduct() {
        let manager = EntitlementManager()
        manager.updateProductMapping(products: [
            makeProduct(storeProductId: "com.app.monthly", entitlements: ["premium"]),
        ])

        // Should not crash, no entitlements added
        manager.handlePurchase(storeProductId: "com.app.nonexistent")

        XCTAssertTrue(manager.activeEntitlements.isEmpty)
        // Status stays .unknown since no known product was purchased
        XCTAssertEqual(manager.subscriptionStatus, .unknown)
    }

    func testHandleRestore() {
        let manager = EntitlementManager()
        manager.updateProductMapping(products: [
            makeProduct(id: "p1", storeProductId: "com.app.monthly", entitlements: ["premium"]),
            makeProduct(id: "p2", storeProductId: "com.app.addon", entitlements: ["analytics"]),
        ])

        manager.handleRestore(storeProductIds: ["com.app.monthly", "com.app.addon"])

        XCTAssertEqual(manager.activeEntitlements, Set(["premium", "analytics"]))
        XCTAssertEqual(manager.subscriptionStatus, .active)
    }

    func testReset() {
        let manager = EntitlementManager()
        manager.updateProductMapping(products: [
            makeProduct(storeProductId: "com.app.monthly", entitlements: ["premium"]),
        ])
        manager.handlePurchase(storeProductId: "com.app.monthly")
        XCTAssertEqual(manager.subscriptionStatus, .active)

        manager.reset()

        XCTAssertTrue(manager.activeEntitlements.isEmpty)
        XCTAssertEqual(manager.subscriptionStatus, .unknown)
    }

    func testEntitlementsForProduct() {
        let manager = EntitlementManager()
        manager.updateProductMapping(products: [
            makeProduct(storeProductId: "com.app.monthly", entitlements: ["premium", "support"]),
        ])

        let result = manager.entitlements(for: "com.app.monthly")
        XCTAssertEqual(Set(result), Set(["premium", "support"]))
    }

    func testEntitlementsForUnknownProduct() {
        let manager = EntitlementManager()
        manager.updateProductMapping(products: [
            makeProduct(storeProductId: "com.app.monthly", entitlements: ["premium"]),
        ])

        let result = manager.entitlements(for: "com.app.nonexistent")
        XCTAssertTrue(result.isEmpty)
    }

    func testHandlePurchaseSetsStatusActive() {
        let manager = EntitlementManager()
        manager.updateProductMapping(products: [
            makeProduct(storeProductId: "com.app.monthly", entitlements: ["premium"]),
        ])

        XCTAssertEqual(manager.subscriptionStatus, .unknown)

        manager.handlePurchase(storeProductId: "com.app.monthly")

        XCTAssertEqual(manager.subscriptionStatus, .active)
    }

    func testMultiplePurchases() {
        let manager = EntitlementManager()
        manager.updateProductMapping(products: [
            makeProduct(id: "p1", storeProductId: "com.app.monthly", entitlements: ["premium"]),
            makeProduct(id: "p2", storeProductId: "com.app.addon", entitlements: ["analytics"]),
            makeProduct(id: "p3", storeProductId: "com.app.extra", entitlements: ["vip", "premium"]),
        ])

        manager.handlePurchase(storeProductId: "com.app.monthly")
        XCTAssertEqual(manager.activeEntitlements, Set(["premium"]))

        manager.handlePurchase(storeProductId: "com.app.addon")
        XCTAssertEqual(manager.activeEntitlements, Set(["premium", "analytics"]))

        manager.handlePurchase(storeProductId: "com.app.extra")
        XCTAssertEqual(manager.activeEntitlements, Set(["premium", "analytics", "vip"]))
    }

    func testThreadSafety() {
        let manager = EntitlementManager()
        manager.updateProductMapping(products: [
            makeProduct(id: "p1", storeProductId: "com.app.monthly", entitlements: ["premium"]),
            makeProduct(id: "p2", storeProductId: "com.app.addon", entitlements: ["analytics"]),
        ])

        let expectation = XCTestExpectation(description: "Concurrent access completes without crash")
        expectation.expectedFulfillmentCount = 4

        let queue1 = DispatchQueue(label: "test.queue.1", attributes: .concurrent)
        let queue2 = DispatchQueue(label: "test.queue.2", attributes: .concurrent)

        // Concurrent writes
        queue1.async {
            for _ in 0..<100 {
                manager.handlePurchase(storeProductId: "com.app.monthly")
            }
            expectation.fulfill()
        }

        queue2.async {
            for _ in 0..<100 {
                manager.handlePurchase(storeProductId: "com.app.addon")
            }
            expectation.fulfill()
        }

        // Concurrent reads
        queue1.async {
            for _ in 0..<100 {
                _ = manager.activeEntitlements
                _ = manager.subscriptionStatus
            }
            expectation.fulfill()
        }

        queue2.async {
            for _ in 0..<100 {
                _ = manager.entitlements(for: "com.app.monthly")
                _ = manager.entitlements(for: "com.app.addon")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)

        // After all concurrent operations, both entitlements should be present
        XCTAssertTrue(manager.activeEntitlements.contains("premium"))
        XCTAssertTrue(manager.activeEntitlements.contains("analytics"))
        XCTAssertEqual(manager.subscriptionStatus, .active)
    }
}
