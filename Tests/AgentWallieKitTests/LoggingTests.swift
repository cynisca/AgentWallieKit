import XCTest
@testable import AgentWallieKit

/// Captures log messages sent through the delegate.
final class LogCapture: AgentWallieDelegate {
    var messages: [(level: LogLevel, message: String)] = []

    func handleLog(level: LogLevel, message: String) {
        messages.append((level: level, message: message))
    }
}

final class LoggingTests: XCTestCase {

    override func tearDown() {
        // Reset to defaults so other tests aren't affected
        AWLogger.configure(logLevel: .warn, delegate: nil)
    }

    // MARK: - AWLogger level filtering

    func testLogRespectLogLevel() {
        let capture = LogCapture()
        AWLogger.configure(logLevel: .warn, delegate: capture)

        AWLogger.log(.debug, "debug msg")
        AWLogger.log(.info, "info msg")
        AWLogger.log(.warn, "warn msg")
        AWLogger.log(.error, "error msg")

        XCTAssertEqual(capture.messages.count, 2)
        XCTAssertEqual(capture.messages[0].message, "warn msg")
        XCTAssertEqual(capture.messages[1].message, "error msg")
    }

    func testLogLevelDebugPassesAll() {
        let capture = LogCapture()
        AWLogger.configure(logLevel: .debug, delegate: capture)

        AWLogger.log(.debug, "d")
        AWLogger.log(.info, "i")
        AWLogger.log(.warn, "w")
        AWLogger.log(.error, "e")

        XCTAssertEqual(capture.messages.count, 4)
    }

    func testLogLevelNoneSuppressesAll() {
        let capture = LogCapture()
        AWLogger.configure(logLevel: .none, delegate: capture)

        AWLogger.log(.debug, "d")
        AWLogger.log(.info, "i")
        AWLogger.log(.warn, "w")
        AWLogger.log(.error, "e")

        XCTAssertEqual(capture.messages.count, 0)
    }

    func testLogRoutesToDelegate() {
        let capture = LogCapture()
        AWLogger.configure(logLevel: .debug, delegate: capture)

        AWLogger.log(.info, "hello from SDK")

        XCTAssertEqual(capture.messages.count, 1)
        XCTAssertEqual(capture.messages[0].level, .info)
        XCTAssertEqual(capture.messages[0].message, "hello from SDK")
    }

    func testLogWithNilDelegateDoesNotCrash() {
        AWLogger.configure(logLevel: .debug, delegate: nil)
        AWLogger.log(.error, "no delegate, no crash")
        // Just verifying no crash — no assertion needed
    }

    // MARK: - PlacementEvaluator logging

    func testPlacementEvaluatorLogsOnNoMatch() {
        let capture = LogCapture()
        AWLogger.configure(logLevel: .warn, delegate: capture)

        let config = SDKConfig(
            campaigns: [
                Campaign(
                    id: "c1",
                    name: "Test Campaign",
                    status: .active,
                    placements: [
                        Placement(id: "p1", name: "other_placement", type: .custom, status: .active)
                    ],
                    audiences: []
                )
            ],
            paywalls: [:],
            products: []
        )

        let store = AssignmentStore()
        let result = PlacementEvaluator.evaluate(
            placement: "rescan",
            config: config,
            context: ["device": ["platform": "ios"]],
            userId: "user1",
            entitlements: [],
            assignmentStore: store
        )

        XCTAssertNil(result)
        // Should have logged a warn about no match
        let noMatchLogs = capture.messages.filter { $0.message.contains("No match for placement") }
        XCTAssertEqual(noMatchLogs.count, 1, "Expected a 'No match' log message")
        XCTAssertTrue(noMatchLogs[0].message.contains("rescan"))
    }

    func testPlacementEvaluatorLogsOnMissingExperiment() {
        let capture = LogCapture()
        AWLogger.configure(logLevel: .warn, delegate: capture)

        let config = SDKConfig(
            campaigns: [
                Campaign(
                    id: "c1",
                    name: "Test Campaign",
                    status: .active,
                    placements: [
                        Placement(id: "p1", name: "rescan", type: .custom, status: .active)
                    ],
                    audiences: [
                        Audience(
                            id: "a1",
                            name: "Everyone",
                            priorityOrder: 0,
                            filters: [],
                            experiment: nil
                        )
                    ]
                )
            ],
            paywalls: [:],
            products: []
        )

        let store = AssignmentStore()
        let result = PlacementEvaluator.evaluate(
            placement: "rescan",
            config: config,
            context: ["device": ["platform": "ios"]],
            userId: "user1",
            entitlements: [],
            assignmentStore: store
        )

        XCTAssertNotNil(result)
        XCTAssertNil(result?.paywallId)
        let experimentLogs = capture.messages.filter { $0.message.contains("no experiment") }
        XCTAssertEqual(experimentLogs.count, 1, "Expected a 'no experiment' log message")
    }

    // MARK: - ConfigManager logging

    func testConfigManagerLogsCorruptCache() {
        let capture = LogCapture()
        AWLogger.configure(logLevel: .error, delegate: capture)

        let suiteName = "LoggingTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set("not valid json".data(using: .utf8), forKey: "com.agentwallie.config.cache")

        let apiClient = APIClient(apiKey: "test", baseURL: URL(string: "https://example.com")!)
        _ = ConfigManager(apiClient: apiClient, defaults: defaults)

        let decodeLogs = capture.messages.filter { $0.message.contains("decode") || $0.message.contains("Decode") }
        XCTAssertFalse(decodeLogs.isEmpty, "Expected a decode error log for corrupt cache")

        // Verify corrupt cache was cleared
        XCTAssertNil(defaults.data(forKey: "com.agentwallie.config.cache"))

        defaults.removePersistentDomain(forName: suiteName)
    }
}
