import Foundation

/// Manages user identity, attributes, and seed for the SDK.
public final class UserManager: @unchecked Sendable {
    private let defaults: UserDefaults
    private let queue = DispatchQueue(label: "com.agentwallie.user-manager")

    private static let userIdKey = "com.agentwallie.userId"
    private static let deviceIdKey = "com.agentwallie.deviceId"
    private static let seedKey = "com.agentwallie.seed"
    private static let attributesKey = "com.agentwallie.attributes"

    public private(set) var userId: String?
    public private(set) var deviceId: String
    public private(set) var seed: Int
    public private(set) var attributes: [String: Any]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Load or create device ID
        if let stored = defaults.string(forKey: UserManager.deviceIdKey) {
            self.deviceId = stored
        } else {
            let id = UUID().uuidString
            defaults.set(id, forKey: UserManager.deviceIdKey)
            self.deviceId = id
        }

        // Load or create seed (0-99)
        if defaults.object(forKey: UserManager.seedKey) != nil {
            self.seed = defaults.integer(forKey: UserManager.seedKey)
        } else {
            let s = Int.random(in: 0...99)
            defaults.set(s, forKey: UserManager.seedKey)
            self.seed = s
        }

        // Load persisted user ID
        self.userId = defaults.string(forKey: UserManager.userIdKey)

        // Load attributes
        self.attributes = (defaults.dictionary(forKey: UserManager.attributesKey)) ?? [:]
    }

    /// Identify the user with a known ID.
    public func identify(userId: String) {
        queue.sync {
            self.userId = userId
            defaults.set(userId, forKey: UserManager.userIdKey)
        }
    }

    /// Reset the user — clears userId and attributes, generates new device ID and seed.
    public func reset() {
        queue.sync {
            self.userId = nil
            self.attributes = [:]
            defaults.removeObject(forKey: UserManager.userIdKey)
            defaults.removeObject(forKey: UserManager.attributesKey)

            let newDeviceId = UUID().uuidString
            self.deviceId = newDeviceId
            defaults.set(newDeviceId, forKey: UserManager.deviceIdKey)

            let newSeed = Int.random(in: 0...99)
            self.seed = newSeed
            defaults.set(newSeed, forKey: UserManager.seedKey)
        }
    }

    /// Set user attributes for audience targeting.
    public func setAttributes(_ attributes: [String: Any]) {
        queue.sync {
            for (key, value) in attributes {
                self.attributes[key] = value
            }
            // Only persist serializable values
            if JSONSerialization.isValidJSONObject(self.attributes) {
                defaults.set(self.attributes, forKey: UserManager.attributesKey)
            }
        }
    }

    /// The effective user ID — either the identified userId or the deviceId.
    public var effectiveUserId: String {
        return userId ?? deviceId
    }

    /// Build the full context dictionary for filter evaluation.
    public func buildContext(eventParams: [String: Any]? = nil) -> [String: Any] {
        var ctx: [String: Any] = [:]
        ctx["user"] = [
            "id": effectiveUserId,
            "seed": seed,
        ].merging(attributes) { _, new in new }

        ctx["device"] = [
            "id": deviceId,
            "platform": "ios",
            "os_version": ProcessInfo.processInfo.operatingSystemVersionString,
        ]

        // Top-level aliases for common filter fields so both "platform"
        // and "device.platform" work in audience filters.
        ctx["platform"] = "ios"
        ctx["os_version"] = ProcessInfo.processInfo.operatingSystemVersionString

        if let params = eventParams {
            ctx["event"] = ["params": params]
        }

        return ctx
    }
}
