import SwiftUI

/// Context passed to custom view builders, providing paywall data.
@available(iOS 16.0, *)
public struct CustomViewContext: Sendable {
    /// The name of the custom view being rendered.
    public let viewName: String
    /// Custom data from the schema's custom_data prop.
    public let customData: [String: AnyCodable]
    /// The current paywall theme.
    public let theme: PaywallTheme?
    /// Product slots defined in the paywall.
    public let products: [ProductSlot]?
    /// User attributes set via setUserAttributes().
    public let userAttributes: [String: AnyCodable]

    public init(
        viewName: String,
        customData: [String: AnyCodable] = [:],
        theme: PaywallTheme? = nil,
        products: [ProductSlot]? = nil,
        userAttributes: [String: AnyCodable] = [:]
    ) {
        self.viewName = viewName
        self.customData = customData
        self.theme = theme
        self.products = products
        self.userAttributes = userAttributes
    }
}

/// Registry for custom SwiftUI views that can be referenced in paywall schemas.
@available(iOS 16.0, *)
public final class CustomViewRegistry: @unchecked Sendable {
    public static let shared = CustomViewRegistry()

    private var builders: [String: @Sendable (CustomViewContext) -> AnyView] = [:]
    private let lock = NSLock()

    private init() {}

    /// Register a simple view with no props.
    public func register<V: View>(name: String, @ViewBuilder builder: @escaping @Sendable () -> V) {
        lock.lock()
        defer { lock.unlock() }
        builders[name] = { _ in AnyView(builder()) }
    }

    /// Register a view that receives context (custom data, theme, products, etc.).
    public func register<V: View>(name: String, builder: @escaping @Sendable (CustomViewContext) -> V) {
        lock.lock()
        defer { lock.unlock() }
        builders[name] = { context in AnyView(builder(context)) }
    }

    /// Look up and build a registered view.
    func resolve(name: String, context: CustomViewContext) -> AnyView? {
        lock.lock()
        defer { lock.unlock() }
        return builders[name]?(context)
    }

    /// Check if a view is registered.
    public func isRegistered(name: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return builders[name] != nil
    }

    /// Unregister a view (useful for testing).
    public func unregister(name: String) {
        lock.lock()
        defer { lock.unlock() }
        builders.removeValue(forKey: name)
    }

    /// Unregister all views (useful for testing).
    public func unregisterAll() {
        lock.lock()
        defer { lock.unlock() }
        builders.removeAll()
    }

    /// List all registered view names.
    public var registeredNames: [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(builders.keys)
    }
}
