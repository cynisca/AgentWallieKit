import XCTest
@testable import AgentWallieKit

final class ExperimentAttributionTests: XCTestCase {

    // MARK: - Helpers

    private func makeStore() -> AssignmentStore {
        let defaults = UserDefaults(suiteName: "com.agentwallie.test.\(UUID().uuidString)")!
        return AssignmentStore(defaults: defaults)
    }

    // MARK: - PlacementResult carries experimentId/variantId

    func testPlacementResultCarriesExperimentAndVariant() {
        let result = PlacementResult(
            campaignId: "camp1",
            audienceId: "aud1",
            experimentId: "exp1",
            variantId: "var1",
            paywallId: "pw1",
            isHoldout: false
        )

        XCTAssertEqual(result.experimentId, "exp1")
        XCTAssertEqual(result.variantId, "var1")
        XCTAssertEqual(result.campaignId, "camp1")
        XCTAssertEqual(result.paywallId, "pw1")
        XCTAssertFalse(result.isHoldout)
    }

    func testPlacementResultHoldoutHasNoVariant() {
        let result = PlacementResult(
            campaignId: "camp1",
            audienceId: "aud1",
            experimentId: "exp1",
            isHoldout: true
        )

        XCTAssertEqual(result.experimentId, "exp1")
        XCTAssertNil(result.variantId)
        XCTAssertNil(result.paywallId)
        XCTAssertTrue(result.isHoldout)
    }

    // MARK: - StoredAssignment includes assignedAt

    func testStoredAssignmentIncludesAssignedAt() {
        let now = Date()
        let assignment = StoredAssignment(
            variantId: "v1",
            paywallId: "pw1",
            isHoldout: false,
            assignedAt: now
        )

        XCTAssertEqual(assignment.assignedAt, now)
    }

    func testStoredAssignmentAssignedAtDefaultsToNow() {
        let before = Date()
        let assignment = StoredAssignment(variantId: "v1", paywallId: "pw1", isHoldout: false)
        let after = Date()

        XCTAssertGreaterThanOrEqual(assignment.assignedAt, before)
        XCTAssertLessThanOrEqual(assignment.assignedAt, after)
    }

    func testStoredAssignmentAssignedAtSurvivesEncodeDecode() throws {
        let now = Date()
        let assignment = StoredAssignment(
            variantId: "v1",
            paywallId: "pw1",
            isHoldout: false,
            assignedAt: now
        )

        let data = try JSONEncoder().encode(assignment)
        let decoded = try JSONDecoder().decode(StoredAssignment.self, from: data)

        // Allow 1ms tolerance for floating point
        XCTAssertEqual(decoded.assignedAt.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 0.001)
    }

    // MARK: - reassignAll clears all assignments

    func testReassignAllClearsAllAssignments() {
        let store = makeStore()

        store.saveAssignment(
            userId: "user1",
            experimentId: "exp1",
            assignment: StoredAssignment(variantId: "v1", paywallId: "pw1", isHoldout: false)
        )
        store.saveAssignment(
            userId: "user2",
            experimentId: "exp2",
            assignment: StoredAssignment(variantId: "v2", paywallId: "pw2", isHoldout: false)
        )

        store.reassignAll()

        XCTAssertNil(store.getAssignment(userId: "user1", experimentId: "exp1"))
        XCTAssertNil(store.getAssignment(userId: "user2", experimentId: "exp2"))
    }

    // MARK: - getAssignmentAge returns correct duration

    func testGetAssignmentAgeReturnsCorrectDuration() {
        let store = makeStore()

        let pastDate = Date().addingTimeInterval(-60) // 60 seconds ago
        let assignment = StoredAssignment(
            variantId: "v1",
            paywallId: "pw1",
            isHoldout: false,
            assignedAt: pastDate
        )
        store.saveAssignment(userId: "user1", experimentId: "exp1", assignment: assignment)

        let age = store.getAssignmentAge(userId: "user1", experimentId: "exp1")
        XCTAssertNotNil(age)
        // Should be approximately 60 seconds (allow some tolerance)
        XCTAssertEqual(age!, 60.0, accuracy: 2.0)
    }

    func testGetAssignmentAgeReturnsNilForMissingAssignment() {
        let store = makeStore()
        let age = store.getAssignmentAge(userId: "user1", experimentId: "nonexistent")
        XCTAssertNil(age)
    }

    // MARK: - clearAssignment removes single assignment

    func testClearAssignmentRemovesSingleAssignment() {
        let store = makeStore()

        store.saveAssignment(
            userId: "user1",
            experimentId: "exp1",
            assignment: StoredAssignment(variantId: "v1", paywallId: "pw1", isHoldout: false)
        )
        store.saveAssignment(
            userId: "user1",
            experimentId: "exp2",
            assignment: StoredAssignment(variantId: "v2", paywallId: "pw2", isHoldout: false)
        )

        store.clearAssignment(userId: "user1", experimentId: "exp1")

        XCTAssertNil(store.getAssignment(userId: "user1", experimentId: "exp1"))
        XCTAssertNotNil(store.getAssignment(userId: "user1", experimentId: "exp2"))
    }

    // MARK: - Preview mode overrides assignment

    func testPreviewModeOverridesAssignment() {
        let store = makeStore()

        // Save a normal assignment
        store.saveAssignment(
            userId: "user1",
            experimentId: "exp1",
            assignment: StoredAssignment(variantId: "v1", paywallId: "pw1", isHoldout: false)
        )

        // Preview overrides to a different variant
        store.saveAssignment(
            userId: "user1",
            experimentId: "exp1",
            assignment: StoredAssignment(variantId: "v2-preview", paywallId: nil, isHoldout: false, assignedAt: Date())
        )

        let retrieved = store.getAssignment(userId: "user1", experimentId: "exp1")
        XCTAssertEqual(retrieved?.variantId, "v2-preview")
        XCTAssertNil(retrieved?.paywallId)
    }

    // MARK: - Clear preview removes override

    func testClearPreviewRemovesOverride() {
        let store = makeStore()

        // Set a preview assignment
        store.saveAssignment(
            userId: "user1",
            experimentId: "exp1",
            assignment: StoredAssignment(variantId: "preview-variant", paywallId: nil, isHoldout: false)
        )

        // Clear the preview
        store.clearAssignment(userId: "user1", experimentId: "exp1")

        XCTAssertNil(store.getAssignment(userId: "user1", experimentId: "exp1"))
    }

    // MARK: - AnalyticsEvent includes experiment_id and variant_id

    func testAnalyticsEventIncludesExperimentAttribution() {
        let event = AnalyticsEvent(
            deviceId: "device-1",
            eventName: "paywall_open",
            campaignId: "camp1",
            paywallId: "pw1",
            experimentId: "exp1",
            variantId: "var1"
        )

        XCTAssertEqual(event.experimentId, "exp1")
        XCTAssertEqual(event.variantId, "var1")
    }

    func testAnalyticsEventExperimentFieldsEncodeToSnakeCase() throws {
        let event = AnalyticsEvent(
            deviceId: "device-1",
            eventName: "paywall_open",
            experimentId: "exp1",
            variantId: "var1"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(event)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["experiment_id"] as? String, "exp1")
        XCTAssertEqual(json?["variant_id"] as? String, "var1")

        // Verify camelCase keys are NOT used
        XCTAssertNil(json?["experimentId"])
        XCTAssertNil(json?["variantId"])
    }

    func testAnalyticsEventWithNilExperimentFields() {
        let event = AnalyticsEvent(
            deviceId: "device-1",
            eventName: "paywall_open"
        )

        XCTAssertNil(event.experimentId)
        XCTAssertNil(event.variantId)
    }

    func testAnalyticsEventExperimentFieldsRoundTrip() throws {
        let event = AnalyticsEvent(
            deviceId: "device-1",
            eventName: "purchase_started",
            experimentId: "exp-abc",
            variantId: "var-xyz"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(event)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AnalyticsEvent.self, from: data)

        XCTAssertEqual(decoded.experimentId, "exp-abc")
        XCTAssertEqual(decoded.variantId, "var-xyz")
    }
}
