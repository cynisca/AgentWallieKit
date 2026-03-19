import Foundation

/// A persisted experiment assignment.
public struct StoredAssignment: Codable, Sendable {
    public let variantId: String?
    public let paywallId: String?
    public let isHoldout: Bool

    public init(variantId: String?, paywallId: String?, isHoldout: Bool) {
        self.variantId = variantId
        self.paywallId = paywallId
        self.isHoldout = isHoldout
    }
}

/// Persists experiment variant assignments keyed by userId + experimentId.
/// Uses UserDefaults for storage.
public final class AssignmentStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let prefix = "com.agentwallie.assignments."
    private let queue = DispatchQueue(label: "com.agentwallie.assignment-store")

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private func key(userId: String, experimentId: String) -> String {
        return "\(prefix)\(userId):\(experimentId)"
    }

    public func getAssignment(userId: String, experimentId: String) -> StoredAssignment? {
        return queue.sync {
            guard let data = defaults.data(forKey: key(userId: userId, experimentId: experimentId)) else {
                return nil
            }
            return try? JSONDecoder().decode(StoredAssignment.self, from: data)
        }
    }

    public func saveAssignment(userId: String, experimentId: String, assignment: StoredAssignment) {
        queue.sync {
            guard let data = try? JSONEncoder().encode(assignment) else { return }
            defaults.set(data, forKey: key(userId: userId, experimentId: experimentId))
        }
    }

    public func clearAssignments(userId: String) {
        queue.sync {
            let allKeys = defaults.dictionaryRepresentation().keys
            for key in allKeys where key.hasPrefix("\(prefix)\(userId):") {
                defaults.removeObject(forKey: key)
            }
        }
    }

    public func clearAll() {
        queue.sync {
            let allKeys = defaults.dictionaryRepresentation().keys
            for key in allKeys where key.hasPrefix(prefix) {
                defaults.removeObject(forKey: key)
            }
        }
    }
}
