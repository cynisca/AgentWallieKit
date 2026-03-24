import Foundation

/// A persisted experiment assignment.
public struct StoredAssignment: Codable, Sendable {
    public let variantId: String?
    public let paywallId: String?
    public let isHoldout: Bool
    public let assignedAt: Date

    public init(variantId: String?, paywallId: String?, isHoldout: Bool, assignedAt: Date = Date()) {
        self.variantId = variantId
        self.paywallId = paywallId
        self.isHoldout = isHoldout
        self.assignedAt = assignedAt
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

    /// Clear a single assignment for a user + experiment.
    public func clearAssignment(userId: String, experimentId: String) {
        queue.sync {
            defaults.removeObject(forKey: key(userId: userId, experimentId: experimentId))
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

    /// Clear all assignments across all users and experiments, forcing re-assignment.
    public func reassignAll() {
        clearAll()
    }

    /// Returns how long ago the assignment was made, or nil if no assignment exists.
    public func getAssignmentAge(userId: String, experimentId: String) -> TimeInterval? {
        guard let assignment = getAssignment(userId: userId, experimentId: experimentId) else {
            return nil
        }
        return Date().timeIntervalSince(assignment.assignedAt)
    }
}
