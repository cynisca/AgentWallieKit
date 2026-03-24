import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Batches and flushes analytics events to the backend.
@available(iOS 16.0, *)
public final class EventTracker: @unchecked Sendable {

    private let apiClient: APIClient
    private let userManager: UserManager
    private let flushInterval: TimeInterval
    private let queue = DispatchQueue(label: "com.agentwallie.event-tracker", attributes: .concurrent)
    private var eventQueue: [AnalyticsEvent] = []
    private var flushTimer: Timer?
    private var backgroundObserver: Any?

    /// Debug data provider for the debug overlay. Set by AgentWallie when debug mode is active.
    public var debugProvider: DebugDataProvider?

    /// Thread-safe storage for recent events (last 50) accessible by the debug overlay.
    private let recentEventsLock = NSLock()
    private var _recentEvents: [AnalyticsEvent] = []
    private let maxRecentEvents = 50

    /// Returns a snapshot of recent events (last 50). Thread-safe.
    public var recentEvents: [AnalyticsEvent] {
        recentEventsLock.lock()
        defer { recentEventsLock.unlock() }
        return _recentEvents
    }

    public init(apiClient: APIClient, userManager: UserManager, flushInterval: TimeInterval = 30) {
        self.apiClient = apiClient
        self.userManager = userManager
        self.flushInterval = flushInterval
        startFlushTimer()
        observeAppLifecycle()
    }

    // MARK: - Public

    /// Track an analytics event.
    public func track(
        name: String,
        properties: [String: Any]? = nil,
        campaignId: String? = nil,
        paywallId: String? = nil,
        experimentId: String? = nil,
        variantId: String? = nil
    ) {
        let codableProps: [String: AnyCodable]? = properties?.mapValues { AnyCodable($0) }

        let event = AnalyticsEvent(
            deviceId: userManager.deviceId,
            userId: userManager.userId,
            eventName: name,
            properties: codableProps,
            campaignId: campaignId,
            paywallId: paywallId,
            experimentId: experimentId,
            variantId: variantId
        )

        // Store in recent events buffer for debug overlay
        recentEventsLock.lock()
        _recentEvents.append(event)
        if _recentEvents.count > maxRecentEvents {
            _recentEvents.removeFirst(_recentEvents.count - maxRecentEvents)
        }
        recentEventsLock.unlock()

        // Notify debug provider if attached
        debugProvider?.recordEvent(name: name, properties: properties)

        queue.async(flags: .barrier) { [weak self] in
            self?.eventQueue.append(event)
        }
    }

    /// Flush all queued events immediately.
    public func flush() {
        var eventsToSend: [AnalyticsEvent] = []

        queue.sync(flags: .barrier) {
            eventsToSend = self.eventQueue
            self.eventQueue.removeAll()
        }

        guard !eventsToSend.isEmpty else { return }

        Task {
            do {
                try await apiClient.postEvents(eventsToSend)
            } catch {
                // Re-queue failed events
                queue.async(flags: .barrier) { [weak self] in
                    self?.eventQueue.insert(contentsOf: eventsToSend, at: 0)
                }
                AWLogger.log(.error, "EventTracker flush failed: \(error)")
            }
        }
    }

    // MARK: - Private

    private func startFlushTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.flushTimer = Timer.scheduledTimer(withTimeInterval: self.flushInterval, repeats: true) { [weak self] _ in
                self?.flush()
            }
        }
    }

    private func observeAppLifecycle() {
        #if canImport(UIKit)
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.flush()
        }
        #endif
    }

    deinit {
        flushTimer?.invalidate()
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
