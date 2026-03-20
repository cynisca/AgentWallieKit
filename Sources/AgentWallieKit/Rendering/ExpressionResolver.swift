import Foundation

// MARK: - Expression Resolver

/// Resolves `{{ ... }}` template expressions in text strings at render time.
///
/// Supported expression paths:
/// - `products.selected.label` / `products.selected.slot` — selected product fields
/// - `products.primary.label` / `products.secondary.label` — product by slot name
/// - `user.<key>` — user attribute value
/// - `theme.<key>` — theme property value (non-color, e.g. font_family)
@available(iOS 16.0, *)
public struct ExpressionResolver {
    public let products: [ProductSlot]?
    public let selectedProductIndex: Int
    public let theme: PaywallTheme?
    public let userAttributes: [String: Any]?

    public init(
        products: [ProductSlot]?,
        selectedProductIndex: Int,
        theme: PaywallTheme?,
        userAttributes: [String: Any]? = nil
    ) {
        self.products = products
        self.selectedProductIndex = selectedProductIndex
        self.theme = theme
        self.userAttributes = userAttributes
    }

    // MARK: - Public API

    /// Resolve all `{{ ... }}` expressions in the given text, returning the result string.
    /// Unknown or unresolvable expressions are left as-is.
    public func resolve(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        let pattern = "\\{\\{\\s*([^}]+?)\\s*\\}\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return text
        }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        guard !matches.isEmpty else { return text }

        var result = text
        // Process in reverse order so replacement ranges stay valid
        for match in matches.reversed() {
            let fullRange = Range(match.range, in: result)!
            let pathRange = Range(match.range(at: 1), in: result)!
            let path = String(result[pathRange]).trimmingCharacters(in: .whitespaces)

            if let resolved = resolveExpression(path: path) {
                result.replaceSubrange(fullRange, with: resolved)
            }
        }

        return result
    }

    // MARK: - Path Resolution

    private func resolveExpression(path: String) -> String? {
        let parts = path.split(separator: ".").map(String.init)
        guard let first = parts.first else { return nil }

        switch first {
        case "products":
            return resolveProductPath(parts: Array(parts.dropFirst()))
        case "user":
            return resolveUserPath(parts: Array(parts.dropFirst()))
        case "theme":
            return resolveThemePath(parts: Array(parts.dropFirst()))
        default:
            return nil
        }
    }

    private func resolveProductPath(parts: [String]) -> String? {
        guard let products = products, !products.isEmpty else { return nil }
        guard let selector = parts.first else { return nil }

        let product: ProductSlot?
        switch selector {
        case "selected":
            if selectedProductIndex >= 0 && selectedProductIndex < products.count {
                product = products[selectedProductIndex]
            } else {
                product = nil
            }
        default:
            // Treat as slot name lookup (e.g., "primary", "secondary")
            product = products.first(where: { $0.slot == selector })
        }

        guard let resolvedProduct = product else { return nil }
        guard parts.count > 1 else { return nil }

        let field = parts[1]
        switch field {
        case "label":
            return resolvedProduct.label
        case "slot":
            return resolvedProduct.slot
        case "product_id":
            return resolvedProduct.productId
        default:
            return nil
        }
    }

    private func resolveUserPath(parts: [String]) -> String? {
        guard let attrs = userAttributes, let key = parts.first else { return nil }
        guard let value = attrs[key] else { return nil }
        return "\(value)"
    }

    private func resolveThemePath(parts: [String]) -> String? {
        guard let theme = theme, let key = parts.first else { return nil }
        switch key {
        case "primary": return theme.primary
        case "secondary": return theme.secondary
        case "background": return theme.background
        case "text_primary": return theme.textPrimary
        case "text_secondary": return theme.textSecondary
        case "accent": return theme.accent
        case "surface": return theme.surface
        case "corner_radius": return "\(theme.cornerRadius)"
        case "font_family": return theme.fontFamily
        default: return nil
        }
    }
}
