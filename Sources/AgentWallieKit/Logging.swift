import Foundation

/// Centralized SDK logger. All SDK components should use `AWLogger.log()` instead of `print()`.
/// Routes messages through the user's configured logLevel and delegate.
enum AWLogger {
    private(set) static var logLevel: LogLevel = .warn
    private(set) static weak var delegate: AgentWallieDelegate?

    static func configure(logLevel: LogLevel, delegate: AgentWallieDelegate?) {
        self.logLevel = logLevel
        self.delegate = delegate
    }

    /// Log a message. The `message` closure is only evaluated if the level passes the threshold.
    static func log(_ level: LogLevel, _ message: @autoclosure () -> String) {
        guard level >= logLevel else { return }
        let msg = message()
        delegate?.handleLog(level: level, message: msg)
        #if DEBUG
        print("[AgentWallie] [\(level)] \(msg)")
        #endif
    }
}
