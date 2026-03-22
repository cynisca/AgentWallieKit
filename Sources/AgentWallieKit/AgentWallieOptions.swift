import Foundation

/// Configuration options for the AgentWallie SDK.
public struct AgentWallieOptions: Sendable {
    /// Default paywall presentation style.
    public var defaultPresentation: PresentationType

    /// Network environment.
    public var networkEnvironment: NetworkEnvironment

    /// Log level.
    public var logLevel: LogLevel

    /// Whether to collect device attributes.
    public var collectDeviceAttributes: Bool

    /// When true, the SDK listens for shake gestures and shows the debug overlay.
    public var enableShakeDebugger: Bool

    public init(
        defaultPresentation: PresentationType = .modal,
        networkEnvironment: NetworkEnvironment = .production,
        logLevel: LogLevel = .warn,
        collectDeviceAttributes: Bool = true,
        enableShakeDebugger: Bool = false
    ) {
        self.defaultPresentation = defaultPresentation
        self.networkEnvironment = networkEnvironment
        self.logLevel = logLevel
        self.collectDeviceAttributes = collectDeviceAttributes
        self.enableShakeDebugger = enableShakeDebugger
    }
}

/// Network environment for the SDK.
public enum NetworkEnvironment: Sendable {
    case production
    case staging
    case custom(URL)

    public var baseURL: URL {
        switch self {
        case .production:
            return URL(string: "https://api.agentwallie.com")!
        case .staging:
            return URL(string: "https://staging-api.agentwallie.com")!
        case .custom(let url):
            return url
        }
    }
}

/// Log level for SDK logging.
public enum LogLevel: Int, Sendable, Comparable {
    case debug = 0
    case info = 1
    case warn = 2
    case error = 3
    case none = 4

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
