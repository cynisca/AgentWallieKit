import XCTest
@testable import AgentWallieKit

final class UserManagerTests: XCTestCase {

    private func makeUserManager() -> UserManager {
        let defaults = UserDefaults(suiteName: "com.agentwallie.test.\(UUID().uuidString)")!
        return UserManager(defaults: defaults)
    }

    // MARK: - Default state

    func testDefaultStateGeneratesDeviceId() {
        let um = makeUserManager()
        XCTAssertFalse(um.deviceId.isEmpty)
        XCTAssertNil(um.userId)
    }

    func testDefaultStateGeneratesSeed() {
        let um = makeUserManager()
        XCTAssertGreaterThanOrEqual(um.seed, 0)
        XCTAssertLessThanOrEqual(um.seed, 99)
    }

    func testDefaultStateHasEmptyAttributes() {
        let um = makeUserManager()
        XCTAssertTrue(um.attributes.isEmpty)
    }

    // MARK: - identify()

    func testIdentifySetsUserId() {
        let um = makeUserManager()
        um.identify(userId: "user-123")
        XCTAssertEqual(um.userId, "user-123")
    }

    func testMultipleIdentifyCallsUpdateUserId() {
        let um = makeUserManager()
        um.identify(userId: "user-1")
        XCTAssertEqual(um.userId, "user-1")
        um.identify(userId: "user-2")
        XCTAssertEqual(um.userId, "user-2")
    }

    // MARK: - reset()

    func testResetClearsUserIdAndAttributes() {
        let um = makeUserManager()
        um.identify(userId: "user-123")
        um.setAttributes(["plan": "pro"])
        XCTAssertNotNil(um.userId)
        XCTAssertFalse(um.attributes.isEmpty)

        um.reset()
        XCTAssertNil(um.userId)
        XCTAssertTrue(um.attributes.isEmpty)
    }

    func testResetGeneratesNewDeviceId() {
        let um = makeUserManager()
        let oldDeviceId = um.deviceId
        um.reset()
        XCTAssertNotEqual(um.deviceId, oldDeviceId)
    }

    func testResetGeneratesNewSeed() {
        // Probabilistic: run multiple times, at least one should differ
        let um = makeUserManager()
        let oldSeed = um.seed
        var changed = false
        for _ in 0..<20 {
            um.reset()
            if um.seed != oldSeed {
                changed = true
                break
            }
        }
        // With 100 possible values, odds of 20 consecutive same values are (1/100)^19 ~ 0
        XCTAssertTrue(changed, "Seed should change after reset (probabilistic)")
    }

    // MARK: - setAttributes()

    func testSetAttributesStoresAttributes() {
        let um = makeUserManager()
        um.setAttributes(["plan": "free", "country": "US"])
        XCTAssertEqual(um.attributes["plan"] as? String, "free")
        XCTAssertEqual(um.attributes["country"] as? String, "US")
    }

    func testSetAttributesMerges() {
        let um = makeUserManager()
        um.setAttributes(["plan": "free"])
        um.setAttributes(["country": "US"])
        XCTAssertEqual(um.attributes["plan"] as? String, "free")
        XCTAssertEqual(um.attributes["country"] as? String, "US")
    }

    func testSetAttributesOverwritesExisting() {
        let um = makeUserManager()
        um.setAttributes(["plan": "free"])
        um.setAttributes(["plan": "pro"])
        XCTAssertEqual(um.attributes["plan"] as? String, "pro")
    }

    // MARK: - effectiveUserId

    func testEffectiveUserIdReturnsIdentifiedUser() {
        let um = makeUserManager()
        um.identify(userId: "user-123")
        XCTAssertEqual(um.effectiveUserId, "user-123")
    }

    func testEffectiveUserIdReturnsDeviceIdWhenAnonymous() {
        let um = makeUserManager()
        XCTAssertEqual(um.effectiveUserId, um.deviceId)
    }

    func testEffectiveUserIdAfterReset() {
        let um = makeUserManager()
        um.identify(userId: "user-123")
        um.reset()
        // After reset, should fall back to new deviceId
        XCTAssertEqual(um.effectiveUserId, um.deviceId)
        XCTAssertNotEqual(um.effectiveUserId, "user-123")
    }

    // MARK: - buildContext()

    func testBuildContextIncludesUserAttributes() {
        let um = makeUserManager()
        um.setAttributes(["plan": "free"])
        let ctx = um.buildContext()

        let user = ctx["user"] as? [String: Any]
        XCTAssertNotNil(user)
        XCTAssertEqual(user?["plan"] as? String, "free")
        XCTAssertEqual(user?["id"] as? String, um.effectiveUserId)
        XCTAssertEqual(user?["seed"] as? Int, um.seed)
    }

    func testBuildContextIncludesDevice() {
        let um = makeUserManager()
        let ctx = um.buildContext()

        let device = ctx["device"] as? [String: Any]
        XCTAssertNotNil(device)
        XCTAssertEqual(device?["id"] as? String, um.deviceId)
        XCTAssertEqual(device?["platform"] as? String, "ios")
    }

    func testBuildContextIncludesEventParams() {
        let um = makeUserManager()
        let ctx = um.buildContext(eventParams: ["screen": "home"])

        let event = ctx["event"] as? [String: Any]
        XCTAssertNotNil(event)
        let params = event?["params"] as? [String: Any]
        XCTAssertEqual(params?["screen"] as? String, "home")
    }

    func testBuildContextWithoutEventParams() {
        let um = makeUserManager()
        let ctx = um.buildContext()
        XCTAssertNil(ctx["event"])
    }

    // MARK: - Persistence

    func testUserIdPersistsAcrossInstances() {
        let suiteName = "com.agentwallie.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let um1 = UserManager(defaults: defaults)
        um1.identify(userId: "persistent-user")

        let um2 = UserManager(defaults: defaults)
        XCTAssertEqual(um2.userId, "persistent-user")
    }

    func testDeviceIdPersistsAcrossInstances() {
        let suiteName = "com.agentwallie.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let um1 = UserManager(defaults: defaults)
        let deviceId = um1.deviceId

        let um2 = UserManager(defaults: defaults)
        XCTAssertEqual(um2.deviceId, deviceId)
    }

    func testSeedPersistsAcrossInstances() {
        let suiteName = "com.agentwallie.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let um1 = UserManager(defaults: defaults)
        let seed = um1.seed

        let um2 = UserManager(defaults: defaults)
        XCTAssertEqual(um2.seed, seed)
    }
}
