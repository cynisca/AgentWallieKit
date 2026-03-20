import XCTest
@testable import AgentWallieKit

final class AssignmentStoreTests: XCTestCase {

    private func makeStore() -> AssignmentStore {
        let defaults = UserDefaults(suiteName: "com.agentwallie.test.\(UUID().uuidString)")!
        return AssignmentStore(defaults: defaults)
    }

    // MARK: - Save and get assignment

    func testSaveAndGetAssignment() {
        let store = makeStore()
        let assignment = StoredAssignment(variantId: "v1", paywallId: "pw1", isHoldout: false)
        store.saveAssignment(userId: "user1", experimentId: "exp1", assignment: assignment)

        let retrieved = store.getAssignment(userId: "user1", experimentId: "exp1")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.variantId, "v1")
        XCTAssertEqual(retrieved?.paywallId, "pw1")
        XCTAssertFalse(retrieved?.isHoldout ?? true)
    }

    // MARK: - Non-existent assignment

    func testGetNonExistentAssignmentReturnsNil() {
        let store = makeStore()
        let result = store.getAssignment(userId: "user1", experimentId: "nonexistent")
        XCTAssertNil(result)
    }

    // MARK: - Clear assignments for user

    func testClearAssignmentsForUser() {
        let store = makeStore()
        let a1 = StoredAssignment(variantId: "v1", paywallId: "pw1", isHoldout: false)
        let a2 = StoredAssignment(variantId: "v2", paywallId: "pw2", isHoldout: false)
        store.saveAssignment(userId: "user1", experimentId: "exp1", assignment: a1)
        store.saveAssignment(userId: "user1", experimentId: "exp2", assignment: a2)

        store.clearAssignments(userId: "user1")

        XCTAssertNil(store.getAssignment(userId: "user1", experimentId: "exp1"))
        XCTAssertNil(store.getAssignment(userId: "user1", experimentId: "exp2"))
    }

    // MARK: - Multiple experiments for same user

    func testMultipleExperimentsForSameUser() {
        let store = makeStore()
        let a1 = StoredAssignment(variantId: "v1", paywallId: "pw1", isHoldout: false)
        let a2 = StoredAssignment(variantId: "v2", paywallId: "pw2", isHoldout: false)

        store.saveAssignment(userId: "user1", experimentId: "exp1", assignment: a1)
        store.saveAssignment(userId: "user1", experimentId: "exp2", assignment: a2)

        let r1 = store.getAssignment(userId: "user1", experimentId: "exp1")
        let r2 = store.getAssignment(userId: "user1", experimentId: "exp2")

        XCTAssertEqual(r1?.variantId, "v1")
        XCTAssertEqual(r2?.variantId, "v2")
    }

    // MARK: - Holdout assignment

    func testHoldoutAssignmentPersistence() {
        let store = makeStore()
        let holdout = StoredAssignment(variantId: nil, paywallId: nil, isHoldout: true)
        store.saveAssignment(userId: "user1", experimentId: "exp1", assignment: holdout)

        let retrieved = store.getAssignment(userId: "user1", experimentId: "exp1")
        XCTAssertNotNil(retrieved)
        XCTAssertNil(retrieved?.variantId)
        XCTAssertNil(retrieved?.paywallId)
        XCTAssertTrue(retrieved?.isHoldout ?? false)
    }

    // MARK: - Different users get independent assignments

    func testDifferentUsersGetIndependentAssignments() {
        let store = makeStore()
        let a1 = StoredAssignment(variantId: "v1", paywallId: "pw1", isHoldout: false)
        let a2 = StoredAssignment(variantId: "v2", paywallId: "pw2", isHoldout: false)

        store.saveAssignment(userId: "user1", experimentId: "exp1", assignment: a1)
        store.saveAssignment(userId: "user2", experimentId: "exp1", assignment: a2)

        let r1 = store.getAssignment(userId: "user1", experimentId: "exp1")
        let r2 = store.getAssignment(userId: "user2", experimentId: "exp1")

        XCTAssertEqual(r1?.variantId, "v1")
        XCTAssertEqual(r2?.variantId, "v2")
    }

    // MARK: - Clear for one user doesn't affect another

    func testClearForOneUserDoesNotAffectAnother() {
        let store = makeStore()
        let a1 = StoredAssignment(variantId: "v1", paywallId: "pw1", isHoldout: false)
        let a2 = StoredAssignment(variantId: "v2", paywallId: "pw2", isHoldout: false)

        store.saveAssignment(userId: "user1", experimentId: "exp1", assignment: a1)
        store.saveAssignment(userId: "user2", experimentId: "exp1", assignment: a2)

        store.clearAssignments(userId: "user1")

        XCTAssertNil(store.getAssignment(userId: "user1", experimentId: "exp1"))
        XCTAssertNotNil(store.getAssignment(userId: "user2", experimentId: "exp1"))
    }

    // MARK: - Overwriting an assignment

    func testOverwriteAssignment() {
        let store = makeStore()
        let a1 = StoredAssignment(variantId: "v1", paywallId: "pw1", isHoldout: false)
        let a2 = StoredAssignment(variantId: "v2", paywallId: "pw2", isHoldout: false)

        store.saveAssignment(userId: "user1", experimentId: "exp1", assignment: a1)
        store.saveAssignment(userId: "user1", experimentId: "exp1", assignment: a2)

        let retrieved = store.getAssignment(userId: "user1", experimentId: "exp1")
        XCTAssertEqual(retrieved?.variantId, "v2")
        XCTAssertEqual(retrieved?.paywallId, "pw2")
    }

    // MARK: - clearAll

    func testClearAll() {
        let store = makeStore()
        store.saveAssignment(userId: "user1", experimentId: "exp1",
                           assignment: StoredAssignment(variantId: "v1", paywallId: "pw1", isHoldout: false))
        store.saveAssignment(userId: "user2", experimentId: "exp2",
                           assignment: StoredAssignment(variantId: "v2", paywallId: "pw2", isHoldout: false))

        store.clearAll()

        XCTAssertNil(store.getAssignment(userId: "user1", experimentId: "exp1"))
        XCTAssertNil(store.getAssignment(userId: "user2", experimentId: "exp2"))
    }

    // MARK: - StoredAssignment Codable

    func testStoredAssignmentCodable() throws {
        let assignment = StoredAssignment(variantId: "v1", paywallId: "pw1", isHoldout: false)
        let data = try JSONEncoder().encode(assignment)
        let decoded = try JSONDecoder().decode(StoredAssignment.self, from: data)
        XCTAssertEqual(decoded.variantId, "v1")
        XCTAssertEqual(decoded.paywallId, "pw1")
        XCTAssertFalse(decoded.isHoldout)
    }
}
