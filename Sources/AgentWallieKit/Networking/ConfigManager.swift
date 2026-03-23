import Foundation

/// Manages config fetching, caching, and periodic refresh.
public final class ConfigManager: @unchecked Sendable {
    private let apiClient: APIClient
    private let cacheKey = "com.agentwallie.config.cache"
    private let defaults: UserDefaults
    private var refreshTask: Task<Void, Never>?

    public private(set) var config: SDKConfig?

    /// How often to refresh config (in seconds). Default: 5 minutes.
    public var refreshInterval: TimeInterval = 300

    /// Callback fired after config is fetched (both initial and refresh).
    /// Use this to trigger product pre-fetching and resolution.
    public var onConfigFetched: ((SDKConfig) -> Void)?

    public init(apiClient: APIClient, defaults: UserDefaults = .standard) {
        self.apiClient = apiClient
        self.defaults = defaults
        loadCachedConfig()
    }

    /// Fetch config from the API and cache it.
    public func fetchConfig() async throws {
        let newConfig = try await apiClient.fetchConfig()
        self.config = newConfig
        cacheConfig(newConfig)
        onConfigFetched?(newConfig)
    }

    /// Start periodic config refresh.
    public func startAutoRefresh() {
        stopAutoRefresh()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64((self?.refreshInterval ?? 300) * 1_000_000_000))
                guard !Task.isCancelled else { break }
                do {
                    try await self?.fetchConfig()
                } catch {
                    AWLogger.log(.error, "Config refresh failed: \(error)")
                }
            }
        }
    }

    /// Stop periodic config refresh.
    public func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    // MARK: - Caching

    private func loadCachedConfig() {
        guard let data = defaults.data(forKey: cacheKey) else { return }
        do {
            config = try JSONDecoder().decode(SDKConfig.self, from: data)
        } catch {
            AWLogger.log(.error, "Failed to decode cached config: \(error)")
            // Clear corrupt cache so we don't keep failing
            defaults.removeObject(forKey: cacheKey)
        }
    }

    private func cacheConfig(_ config: SDKConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: cacheKey)
    }

    deinit {
        refreshTask?.cancel()
    }
}
