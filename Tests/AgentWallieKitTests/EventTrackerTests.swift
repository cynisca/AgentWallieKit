import XCTest
@testable import AgentWallieKit

final class EventTrackerTests: XCTestCase {

    // MARK: - AnalyticsEvent Tests

    func testAnalyticsEventCreation() throws {
        let event = AnalyticsEvent(
            deviceId: "device-123",
            userId: "user-456",
            eventName: "paywall_open",
            properties: ["screen": AnyCodable("home")],
            campaignId: "camp_1",
            paywallId: "pw_1"
        )

        XCTAssertEqual(event.deviceId, "device-123")
        XCTAssertEqual(event.userId, "user-456")
        XCTAssertEqual(event.eventName, "paywall_open")
        XCTAssertEqual(event.campaignId, "camp_1")
        XCTAssertEqual(event.paywallId, "pw_1")
        XCTAssertNotNil(event.properties)
        XCTAssertFalse(event.id.isEmpty)
    }

    func testAnalyticsEventEncodeDecode() throws {
        let event = AnalyticsEvent(
            id: "evt-1",
            deviceId: "device-123",
            userId: "user-456",
            eventName: "purchase_started",
            properties: [
                "product": AnyCodable("premium"),
                "price": AnyCodable(9.99),
                "trial": AnyCodable(true)
            ],
            campaignId: "camp_1",
            paywallId: "pw_1"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(event)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AnalyticsEvent.self, from: data)

        XCTAssertEqual(decoded.id, "evt-1")
        XCTAssertEqual(decoded.deviceId, "device-123")
        XCTAssertEqual(decoded.userId, "user-456")
        XCTAssertEqual(decoded.eventName, "purchase_started")
        XCTAssertEqual(decoded.campaignId, "camp_1")
        XCTAssertEqual(decoded.paywallId, "pw_1")
        XCTAssertEqual(decoded.properties?["product"]?.value as? String, "premium")
        XCTAssertEqual(decoded.properties?["price"]?.value as? Double, 9.99)
        XCTAssertEqual(decoded.properties?["trial"]?.value as? Bool, true)
    }

    func testAnalyticsEventCodingKeys() throws {
        let event = AnalyticsEvent(
            deviceId: "dev-1",
            eventName: "test_event",
            campaignId: "c1",
            paywallId: "p1"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(event)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Verify snake_case keys are used
        XCTAssertNotNil(json?["device_id"])
        XCTAssertNotNil(json?["event_name"])
        XCTAssertNotNil(json?["campaign_id"])
        XCTAssertNotNil(json?["paywall_id"])

        // Verify camelCase keys are NOT used
        XCTAssertNil(json?["deviceId"])
        XCTAssertNil(json?["eventName"])
        XCTAssertNil(json?["campaignId"])
        XCTAssertNil(json?["paywallId"])
    }

    func testAnalyticsEventWithNilProperties() throws {
        let event = AnalyticsEvent(
            deviceId: "dev-1",
            eventName: "paywall_close"
        )

        XCTAssertNil(event.userId)
        XCTAssertNil(event.properties)
        XCTAssertNil(event.campaignId)
        XCTAssertNil(event.paywallId)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(event)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AnalyticsEvent.self, from: data)

        XCTAssertNil(decoded.userId)
        XCTAssertNil(decoded.properties)
    }

    func testAnalyticsEventBatchEncoding() throws {
        let events = [
            AnalyticsEvent(deviceId: "dev-1", eventName: "paywall_open"),
            AnalyticsEvent(deviceId: "dev-1", eventName: "purchase_started"),
            AnalyticsEvent(deviceId: "dev-1", eventName: "transaction_complete"),
        ]

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(["events": events])
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let eventsArray = json?["events"] as? [[String: Any]]
        XCTAssertEqual(eventsArray?.count, 3)
        XCTAssertEqual(eventsArray?[0]["event_name"] as? String, "paywall_open")
        XCTAssertEqual(eventsArray?[1]["event_name"] as? String, "purchase_started")
        XCTAssertEqual(eventsArray?[2]["event_name"] as? String, "transaction_complete")
    }

    func testAnalyticsEventUniqueIds() throws {
        let event1 = AnalyticsEvent(deviceId: "dev-1", eventName: "event_1")
        let event2 = AnalyticsEvent(deviceId: "dev-1", eventName: "event_2")

        XCTAssertNotEqual(event1.id, event2.id, "Each event should have a unique ID")
    }

    // MARK: - EventTracker integration test (non-network)

    @available(iOS 16.0, *)
    func testEventTrackerCanBeCreated() throws {
        let defaults = UserDefaults(suiteName: "com.agentwallie.test.\(UUID().uuidString)")!
        let userManager = UserManager(defaults: defaults)
        let apiClient = APIClient(apiKey: "test-key", baseURL: URL(string: "https://test.example.com")!)

        let tracker = EventTracker(apiClient: apiClient, userManager: userManager, flushInterval: 9999)

        // Should be able to track without crashing
        tracker.track(name: "test_event", properties: ["key": "value"])
        tracker.track(name: "paywall_open", campaignId: "c1", paywallId: "p1")

        // Flush should not crash even though network will fail
        tracker.flush()

        // Allow async work to complete
        let expectation = XCTestExpectation(description: "Flush completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }
}
