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
    private static let templateRegex = try! NSRegularExpression(pattern: "\\{\\{\\s*([^}]+?)\\s*\\}\\}")

    public let products: [ProductSlot]?
    public let selectedProductIndex: Int
    public let theme: PaywallTheme?
    public let userAttributes: [String: Any]?
    public let resolvedProducts: [ResolvedProductInfo]?
    public let awProducts: [AWProduct]?

    /// Pre-indexed lookups for O(1) access by slot name
    private let productsBySlot: [String: ProductSlot]
    private let resolvedProductsBySlot: [String: ResolvedProductInfo]

    public init(
        products: [ProductSlot]?,
        selectedProductIndex: Int,
        theme: PaywallTheme?,
        userAttributes: [String: Any]? = nil,
        resolvedProducts: [ResolvedProductInfo]? = nil,
        awProducts: [AWProduct]? = nil
    ) {
        self.products = products
        self.selectedProductIndex = selectedProductIndex
        self.theme = theme
        self.userAttributes = userAttributes
        self.resolvedProducts = resolvedProducts
        self.awProducts = awProducts

        // Build O(1) lookup dictionaries
        var pBySlot: [String: ProductSlot] = [:]
        if let products = products {
            for p in products {
                pBySlot[p.slot] = p
            }
        }
        self.productsBySlot = pBySlot

        var rpBySlot: [String: ResolvedProductInfo] = [:]
        if let resolvedProducts = resolvedProducts {
            for rp in resolvedProducts {
                rpBySlot[rp.slot] = rp
            }
        }
        self.resolvedProductsBySlot = rpBySlot
    }

    // MARK: - Public API

    /// Resolve all `{{ ... }}` expressions in the given text, returning the result string.
    /// Unknown or unresolvable expressions are left as-is.
    public func resolve(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        let nsText = text as NSString
        let matches = Self.templateRegex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

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
            // Treat as slot name lookup (e.g., "primary", "secondary") — O(1)
            product = productsBySlot[selector]
        }

        guard let resolvedProduct = product else { return nil }
        guard parts.count > 1 else { return nil }

        let field = parts[1]

        // First try resolving from ResolvedProductInfo for live pricing data
        if let resolvedInfo = findResolvedProduct(forSlot: resolvedProduct.slot) {
            switch field {
            case "price":
                return resolvedInfo.price
            case "price_per_month":
                return resolvedInfo.pricePerMonth
            case "period":
                return resolvedInfo.period
            case "period_label":
                return resolvedInfo.periodLabel
            case "trial_period":
                return resolvedInfo.trialPeriod
            case "trial_price":
                return resolvedInfo.trialPrice
            case "savings_percentage":
                if let savings = resolvedInfo.savingsPercentage {
                    return String(savings)
                }
                return nil
            case "has_trial":
                return String(resolvedInfo.trialPeriod != nil)
            default:
                break
            }
        } else if let awProducts = awProducts {
            // Fallback: when resolvedProducts is empty (StoreKit fetch failed),
            // try to resolve from AWProduct display data
            if let awProduct = awProducts.first(where: { $0.storeProductId == resolvedProduct.productId || $0.id == resolvedProduct.productId }) {
                switch field {
                case "price":
                    if let dp = awProduct.displayPrice { return dp }
                case "period", "period_label":
                    if let dp = awProduct.displayPeriod { return dp }
                default:
                    break
                }
            }
        }

        // Fall back to ProductSlot fields
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

    /// Find the ResolvedProductInfo for a given slot name — O(1) via pre-indexed dictionary.
    private func findResolvedProduct(forSlot slot: String) -> ResolvedProductInfo? {
        resolvedProductsBySlot[slot]
    }

    private func resolveUserPath(parts: [String]) -> String? {
        guard let attrs = userAttributes, let key = parts.first else { return nil }
        guard let value = attrs[key] else { return nil }
        return "\(value)"
    }

    private func resolveThemePath(parts: [String]) -> String? {
        guard let theme = theme, let key = parts.first else { return nil }
        return theme.value(forKey: key)
    }
}
