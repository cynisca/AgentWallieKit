import XCTest
@testable import AgentWallieKit

final class ProductModelTests: XCTestCase {

    // MARK: - Helper

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - AWProduct encoding/decoding

    func testAWProductEncodingDecoding() throws {
        let product = AWProduct(
            id: "prod_1",
            name: "Premium Monthly",
            store: .apple,
            storeProductId: "com.app.premium.monthly",
            entitlements: ["premium", "no_ads"],
            basePlanId: nil,
            offerIds: ["intro_offer"],
            displayPrice: "$9.99",
            displayPeriod: "month"
        )

        let decoded = try roundTrip(product)
        XCTAssertEqual(decoded.id, "prod_1")
        XCTAssertEqual(decoded.name, "Premium Monthly")
        XCTAssertEqual(decoded.store, .apple)
        XCTAssertEqual(decoded.storeProductId, "com.app.premium.monthly")
        XCTAssertEqual(decoded.entitlements, ["premium", "no_ads"])
        XCTAssertNil(decoded.basePlanId)
        XCTAssertEqual(decoded.offerIds, ["intro_offer"])
        XCTAssertEqual(decoded.displayPrice, "$9.99")
        XCTAssertEqual(decoded.displayPeriod, "month")
    }

    func testAWProductMinimalFields() throws {
        let product = AWProduct(
            id: "prod_2",
            name: "Basic",
            store: .stripe,
            storeProductId: "price_abc123",
            entitlements: []
        )

        let decoded = try roundTrip(product)
        XCTAssertEqual(decoded.id, "prod_2")
        XCTAssertEqual(decoded.store, .stripe)
        XCTAssertNil(decoded.basePlanId)
        XCTAssertNil(decoded.offerIds)
        XCTAssertNil(decoded.displayPrice)
        XCTAssertNil(decoded.displayPeriod)
    }

    func testAWProductFromJSON() throws {
        let json = """
        {
            "id": "prod_1",
            "name": "Annual",
            "store": "apple",
            "store_product_id": "com.app.annual",
            "entitlements": ["pro"],
            "base_plan_id": "bp_1",
            "offer_ids": ["offer_1", "offer_2"],
            "display_price": "$79.99",
            "display_period": "year"
        }
        """
        let data = json.data(using: .utf8)!
        let product = try JSONDecoder().decode(AWProduct.self, from: data)

        XCTAssertEqual(product.id, "prod_1")
        XCTAssertEqual(product.storeProductId, "com.app.annual")
        XCTAssertEqual(product.basePlanId, "bp_1")
        XCTAssertEqual(product.offerIds, ["offer_1", "offer_2"])
        XCTAssertEqual(product.displayPrice, "$79.99")
        XCTAssertEqual(product.displayPeriod, "year")
    }

    func testAWProductSnakeCaseEncoding() throws {
        let product = AWProduct(
            id: "p1",
            name: "Test",
            store: .apple,
            storeProductId: "com.test",
            entitlements: []
        )

        let data = try JSONEncoder().encode(product)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json?["store_product_id"])
        XCTAssertNil(json?["storeProductId"])
    }

    // MARK: - ProductSlot

    func testProductSlotWithProductId() throws {
        let slot = ProductSlot(slot: "primary", label: "Annual", productId: "prod_1")
        let decoded = try roundTrip(slot)
        XCTAssertEqual(decoded.slot, "primary")
        XCTAssertEqual(decoded.label, "Annual")
        XCTAssertEqual(decoded.productId, "prod_1")
    }

    func testProductSlotWithoutProductId() throws {
        let slot = ProductSlot(slot: "secondary", label: "Monthly")
        let decoded = try roundTrip(slot)
        XCTAssertEqual(decoded.slot, "secondary")
        XCTAssertEqual(decoded.label, "Monthly")
        XCTAssertNil(decoded.productId)
    }

    func testProductSlotFromJSON() throws {
        let json = """
        {"slot": "primary", "label": "Best Deal", "product_id": "prod_123"}
        """
        let data = json.data(using: .utf8)!
        let slot = try JSONDecoder().decode(ProductSlot.self, from: data)
        XCTAssertEqual(slot.productId, "prod_123")
    }

    func testProductSlotFromJSONWithoutProductId() throws {
        let json = """
        {"slot": "tertiary", "label": "Weekly"}
        """
        let data = json.data(using: .utf8)!
        let slot = try JSONDecoder().decode(ProductSlot.self, from: data)
        XCTAssertEqual(slot.slot, "tertiary")
        XCTAssertNil(slot.productId)
    }

    // MARK: - StoreType

    func testStoreTypeApple() throws {
        let decoded = try roundTrip(StoreType.apple)
        XCTAssertEqual(decoded, .apple)
        XCTAssertEqual(StoreType.apple.rawValue, "apple")
    }

    func testStoreTypeGoogle() throws {
        let decoded = try roundTrip(StoreType.google)
        XCTAssertEqual(decoded, .google)
        XCTAssertEqual(StoreType.google.rawValue, "google")
    }

    func testStoreTypeStripe() throws {
        let decoded = try roundTrip(StoreType.stripe)
        XCTAssertEqual(decoded, .stripe)
        XCTAssertEqual(StoreType.stripe.rawValue, "stripe")
    }

    func testStoreTypeFromJSON() throws {
        for raw in ["apple", "google", "stripe"] {
            let json = "\"\(raw)\""
            let data = json.data(using: .utf8)!
            let store = try JSONDecoder().decode(StoreType.self, from: data)
            XCTAssertEqual(store.rawValue, raw)
        }
    }
}
