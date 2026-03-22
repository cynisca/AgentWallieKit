import Foundation
import SwiftUI

/// Debug event entry for display in the debug overlay.
public struct DebugEventEntry: Identifiable, Sendable {
    public let id: String
    public let timestamp: Date
    public let eventName: String
    public let propertiesSummary: String

    public init(id: String = UUID().uuidString, timestamp: Date = Date(), eventName: String, propertiesSummary: String = "") {
        self.id = id
        self.timestamp = timestamp
        self.eventName = eventName
        self.propertiesSummary = propertiesSummary
    }
}

/// Debug product entry for display in the debug overlay.
public struct DebugProductEntry: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let store: String
    public let storeProductId: String
    public let fetchStatus: String  // "fetched", "failed", "pending"
    public let resolvedPrice: String
    public let entitlements: [String]

    public init(id: String, name: String, store: String, storeProductId: String, fetchStatus: String, resolvedPrice: String, entitlements: [String]) {
        self.id = id
        self.name = name
        self.store = store
        self.storeProductId = storeProductId
        self.fetchStatus = fetchStatus
        self.resolvedPrice = resolvedPrice
        self.entitlements = entitlements
    }
}

/// Debug assignment entry for display in the debug overlay.
public struct DebugAssignmentEntry: Identifiable, Sendable {
    public let id: String  // experimentId
    public let experimentId: String
    public let variantId: String?
    public let paywallId: String?
    public let isHoldout: Bool

    public init(experimentId: String, variantId: String?, paywallId: String?, isHoldout: Bool) {
        self.id = experimentId
        self.experimentId = experimentId
        self.variantId = variantId
        self.paywallId = paywallId
        self.isHoldout = isHoldout
    }
}

/// Thread-safe event buffer used by DebugDataProvider.
/// Separated from the @MainActor class so it can be accessed from any thread.
public final class DebugEventBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer: [DebugEventEntry] = []
    private let maxEvents = 50

    public init() {}

    /// Append an event. Thread-safe.
    public func append(_ entry: DebugEventEntry) {
        lock.lock()
        buffer.append(entry)
        if buffer.count > maxEvents {
            buffer.removeFirst(buffer.count - maxEvents)
        }
        lock.unlock()
    }

    /// Returns a snapshot of all buffered events. Thread-safe.
    public var snapshot: [DebugEventEntry] {
        lock.lock()
        defer { lock.unlock() }
        return buffer
    }

    /// Returns the count of buffered events. Thread-safe.
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return buffer.count
    }
}

/// Observable data provider that collects debug information from SDK internals.
@available(iOS 16.0, *)
@MainActor
public final class DebugDataProvider: ObservableObject {

    // MARK: - SDK Status

    @Published public var isConfigured: Bool = false
    @Published public var apiKey: String = ""
    @Published public var apiBaseURL: String = ""
    @Published public var configStatus: String = "unknown"  // "loaded", "cached", "error"
    @Published public var configLastFetched: Date?
    @Published public var campaignsCount: Int = 0
    @Published public var paywallsCount: Int = 0
    @Published public var productsCount: Int = 0

    // MARK: - User Info

    @Published public var userId: String = ""
    @Published public var isIdentified: Bool = false
    @Published public var subscriptionStatus: String = "unknown"
    @Published public var activeEntitlements: [String] = []
    @Published public var userAttributes: [String: String] = [:]
    @Published public var userSeed: Int = 0

    // MARK: - Products

    @Published public var products: [DebugProductEntry] = []

    // MARK: - Events

    @Published public var recentEvents: [DebugEventEntry] = []

    // MARK: - Assignments

    @Published public var assignments: [DebugAssignmentEntry] = []

    // MARK: - Placement Evaluator Result

    @Published public var placementResult: String = ""

    // MARK: - Internal

    /// Thread-safe event buffer accessible from any thread.
    public nonisolated let eventBuffer = DebugEventBuffer()

    public init() {}

    // MARK: - Event Recording (thread-safe)

    /// Append a debug event. Thread-safe, can be called from any thread.
    public nonisolated func recordEvent(name: String, properties: [String: Any]? = nil) {
        let summary: String
        if let props = properties {
            let pairs = props.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            summary = pairs
        } else {
            summary = ""
        }

        let entry = DebugEventEntry(
            timestamp: Date(),
            eventName: name,
            propertiesSummary: summary
        )

        eventBuffer.append(entry)
        let snapshot = eventBuffer.snapshot

        Task { @MainActor in
            self.recentEvents = snapshot
        }
    }

    /// Thread-safe read of buffered events count.
    public nonisolated var bufferedEventCount: Int {
        eventBuffer.count
    }

    /// Thread-safe read of buffered events.
    public nonisolated var bufferedEvents: [DebugEventEntry] {
        eventBuffer.snapshot
    }

    // MARK: - Data Collection

    /// Collect current state from SDK internals.
    public func collectStatus(
        isConfigured: Bool,
        apiKey: String?,
        baseURL: URL?,
        config: SDKConfig?,
        configLoaded: Bool
    ) {
        self.isConfigured = isConfigured

        if let key = apiKey {
            let masked = String(key.prefix(8)) + "..."
            self.apiKey = masked
        } else {
            self.apiKey = "(not set)"
        }

        self.apiBaseURL = baseURL?.absoluteString ?? "(not set)"

        if config != nil {
            self.configStatus = configLoaded ? "loaded" : "cached"
            self.campaignsCount = config!.campaigns.count
            self.paywallsCount = config!.paywalls.count
            self.productsCount = config!.products.count
        } else {
            self.configStatus = "error"
            self.campaignsCount = 0
            self.paywallsCount = 0
            self.productsCount = 0
        }

        self.configLastFetched = configLoaded ? Date() : nil
    }

    /// Collect user info from UserManager.
    public func collectUserInfo(
        userId: String?,
        deviceId: String,
        seed: Int,
        attributes: [String: Any],
        subscriptionStatus: SubscriptionStatus,
        entitlements: Set<String>
    ) {
        self.isIdentified = userId != nil
        self.userId = userId ?? deviceId
        self.userSeed = seed
        self.userAttributes = attributes.mapValues { "\($0)" }

        switch subscriptionStatus {
        case .unknown: self.subscriptionStatus = "unknown"
        case .active: self.subscriptionStatus = "active"
        case .inactive: self.subscriptionStatus = "inactive"
        case .expired: self.subscriptionStatus = "expired"
        }

        self.activeEntitlements = Array(entitlements).sorted()
    }

    /// Collect product info from config and resolved products.
    public func collectProducts(
        configProducts: [AWProduct],
        resolvedProducts: [ResolvedProductInfo]
    ) {
        let resolvedMap = Dictionary(
            resolvedProducts.map { ($0.storeProductId ?? "", $0) },
            uniquingKeysWith: { first, _ in first }
        )

        self.products = configProducts.map { product in
            let resolved = resolvedMap[product.storeProductId]
            let fetchStatus: String
            let resolvedPrice: String

            if let r = resolved {
                fetchStatus = r.price.isEmpty ? "pending" : "fetched"
                resolvedPrice = r.price
            } else {
                fetchStatus = "pending"
                resolvedPrice = product.displayPrice ?? "(no price)"
            }

            return DebugProductEntry(
                id: product.id,
                name: product.name,
                store: product.store.rawValue,
                storeProductId: product.storeProductId,
                fetchStatus: fetchStatus,
                resolvedPrice: resolvedPrice,
                entitlements: product.entitlements
            )
        }
    }

    /// Collect experiment assignments.
    public func collectAssignments(
        assignmentStore: AssignmentStore,
        userId: String,
        config: SDKConfig?
    ) {
        guard let config = config else {
            self.assignments = []
            return
        }

        var entries: [DebugAssignmentEntry] = []

        for campaign in config.campaigns {
            for audience in campaign.audiences {
                guard let experiment = audience.experiment else { continue }
                if let stored = assignmentStore.getAssignment(userId: userId, experimentId: experiment.id) {
                    entries.append(DebugAssignmentEntry(
                        experimentId: experiment.id,
                        variantId: stored.variantId,
                        paywallId: stored.paywallId,
                        isHoldout: stored.isHoldout
                    ))
                }
            }
        }

        self.assignments = entries
    }
}
