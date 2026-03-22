import XCTest
@testable import AgentWallieKit

@available(iOS 16.0, *)
final class DebugDataProviderTests: XCTestCase {

    // MARK: - Config Status

    @MainActor
    func testCollectsConfigStatus() throws {
        let provider = DebugDataProvider()

        let config = SDKConfig(
            campaigns: [
                Campaign(
                    id: "c1",
                    name: "Test Campaign",
                    status: .active,
                    placements: [],
                    audiences: []
                )
            ],
            paywalls: [:],
            products: [
                AWProduct(
                    id: "p1",
                    name: "Premium",
                    store: .apple,
                    storeProductId: "com.app.premium",
                    entitlements: ["pro"]
                )
            ]
        )

        provider.collectStatus(
            isConfigured: true,
            apiKey: "pk_live_abcdef1234567890",
            baseURL: URL(string: "https://api.agentwallie.com"),
            config: config,
            configLoaded: true
        )

        XCTAssertTrue(provider.isConfigured)
        XCTAssertEqual(provider.apiKey, "pk_live_...")
        XCTAssertEqual(provider.apiBaseURL, "https://api.agentwallie.com")
        XCTAssertEqual(provider.configStatus, "loaded")
        XCTAssertEqual(provider.campaignsCount, 1)
        XCTAssertEqual(provider.paywallsCount, 0)
        XCTAssertEqual(provider.productsCount, 1)
        XCTAssertNotNil(provider.configLastFetched)
    }

    @MainActor
    func testCollectsConfigStatusWhenNotConfigured() throws {
        let provider = DebugDataProvider()

        provider.collectStatus(
            isConfigured: false,
            apiKey: nil,
            baseURL: nil,
            config: nil,
            configLoaded: false
        )

        XCTAssertFalse(provider.isConfigured)
        XCTAssertEqual(provider.apiKey, "(not set)")
        XCTAssertEqual(provider.apiBaseURL, "(not set)")
        XCTAssertEqual(provider.configStatus, "error")
        XCTAssertEqual(provider.campaignsCount, 0)
    }

    // MARK: - User Info

    @MainActor
    func testCollectsUserInfo() throws {
        let provider = DebugDataProvider()

        provider.collectUserInfo(
            userId: "user-123",
            deviceId: "device-abc",
            seed: 42,
            attributes: ["plan": "premium", "age": 25],
            subscriptionStatus: .active,
            entitlements: Set(["pro", "analytics"])
        )

        XCTAssertTrue(provider.isIdentified)
        XCTAssertEqual(provider.userId, "user-123")
        XCTAssertEqual(provider.userSeed, 42)
        XCTAssertEqual(provider.subscriptionStatus, "active")
        XCTAssertEqual(provider.activeEntitlements, ["analytics", "pro"])
        XCTAssertEqual(provider.userAttributes["plan"], "premium")
        XCTAssertEqual(provider.userAttributes["age"], "25")
    }

    @MainActor
    func testCollectsAnonymousUserInfo() throws {
        let provider = DebugDataProvider()

        provider.collectUserInfo(
            userId: nil,
            deviceId: "device-abc",
            seed: 77,
            attributes: [:],
            subscriptionStatus: .unknown,
            entitlements: Set()
        )

        XCTAssertFalse(provider.isIdentified)
        XCTAssertEqual(provider.userId, "device-abc")
        XCTAssertEqual(provider.subscriptionStatus, "unknown")
        XCTAssertTrue(provider.activeEntitlements.isEmpty)
    }

    // MARK: - Products

    @MainActor
    func testCollectsProductList() throws {
        let provider = DebugDataProvider()

        let configProducts = [
            AWProduct(
                id: "p1",
                name: "Monthly",
                store: .apple,
                storeProductId: "com.app.monthly",
                entitlements: ["pro"],
                displayPrice: "$9.99"
            ),
            AWProduct(
                id: "p2",
                name: "Annual",
                store: .apple,
                storeProductId: "com.app.annual",
                entitlements: ["pro"],
                displayPrice: "$49.99"
            )
        ]

        let resolved = [
            ResolvedProductInfo(
                slot: "primary",
                label: "Monthly",
                productId: "p1",
                storeProductId: "com.app.monthly",
                price: "$9.99",
                period: "month",
                periodLabel: "/mo"
            )
        ]

        provider.collectProducts(configProducts: configProducts, resolvedProducts: resolved)

        XCTAssertEqual(provider.products.count, 2)

        let monthly = provider.products.first(where: { $0.id == "p1" })
        XCTAssertNotNil(monthly)
        XCTAssertEqual(monthly?.name, "Monthly")
        XCTAssertEqual(monthly?.store, "apple")
        XCTAssertEqual(monthly?.fetchStatus, "fetched")
        XCTAssertEqual(monthly?.resolvedPrice, "$9.99")
        XCTAssertEqual(monthly?.entitlements, ["pro"])

        let annual = provider.products.first(where: { $0.id == "p2" })
        XCTAssertNotNil(annual)
        XCTAssertEqual(annual?.fetchStatus, "pending")
    }

    // MARK: - Recent Events (max 50)

    @MainActor
    func testCollectsRecentEventsMax50() throws {
        let provider = DebugDataProvider()

        for i in 0..<60 {
            provider.recordEvent(name: "event_\(i)", properties: ["index": i])
        }

        // Allow async MainActor updates to settle
        let expectation = XCTestExpectation(description: "Events buffer fills")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(provider.bufferedEventCount, 50)

        let events = provider.bufferedEvents
        // The first 10 events should have been dropped
        XCTAssertEqual(events.first?.eventName, "event_10")
        XCTAssertEqual(events.last?.eventName, "event_59")
    }

    // MARK: - Assignments

    @MainActor
    func testCollectsAssignments() throws {
        let provider = DebugDataProvider()
        let defaults = UserDefaults(suiteName: "com.agentwallie.test.debug.\(UUID().uuidString)")!
        let store = AssignmentStore(defaults: defaults)

        let experiment = Experiment(
            id: "exp-1",
            variants: [ExperimentVariant(id: "v1", paywallId: "pw-1", trafficPercentage: 100)],
            holdoutPercentage: 0,
            status: .running
        )

        let campaign = Campaign(
            id: "c1",
            name: "Test",
            status: .active,
            placements: [],
            audiences: [
                Audience(
                    id: "a1",
                    name: "Everyone",
                    priorityOrder: 0,
                    filters: [],
                    experiment: experiment
                )
            ]
        )

        let config = SDKConfig(campaigns: [campaign], paywalls: [:])

        store.saveAssignment(
            userId: "user-1",
            experimentId: "exp-1",
            assignment: StoredAssignment(variantId: "v1", paywallId: "pw-1", isHoldout: false)
        )

        provider.collectAssignments(assignmentStore: store, userId: "user-1", config: config)

        XCTAssertEqual(provider.assignments.count, 1)
        XCTAssertEqual(provider.assignments.first?.experimentId, "exp-1")
        XCTAssertEqual(provider.assignments.first?.variantId, "v1")
        XCTAssertEqual(provider.assignments.first?.paywallId, "pw-1")
        XCTAssertFalse(provider.assignments.first?.isHoldout ?? true)

        // Clean up
        defaults.removePersistentDomain(forName: "com.agentwallie.test.debug")
    }

    // MARK: - Thread Safety

    @MainActor
    func testThreadSafeEventAppend() throws {
        let provider = DebugDataProvider()
        let group = DispatchGroup()
        let iterations = 100

        for i in 0..<iterations {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                provider.recordEvent(name: "concurrent_event_\(i)")
                group.leave()
            }
        }

        group.wait()

        // Allow MainActor to settle
        let expectation = XCTestExpectation(description: "Concurrent events settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Should have exactly 50 (max) since we inserted 100
        XCTAssertEqual(provider.bufferedEventCount, 50)

        // All events should have valid names (no corruption)
        let events = provider.bufferedEvents
        for event in events {
            XCTAssertTrue(event.eventName.hasPrefix("concurrent_event_"))
        }
    }
}
