import Foundation

// MARK: - Condition Operator Constants

/// Known condition operator string values matching the JSON schema.
enum ConditionOperatorValue {
    static let `is` = "is"
    static let isNot = "is_not"
    static let gt = "gt"
    static let gte = "gte"
    static let lt = "lt"
    static let lte = "lte"
    static let contains = "contains"
    static let exists = "exists"
    static let notExists = "not_exists"
}

// MARK: - Condition Evaluator

/// Evaluates component conditions to determine whether a component should render.
///
/// Uses dot-notation paths to resolve field values from context, similar to FilterEngine.
/// Supported path prefixes: `products.selected.*`, `products.<slot>.*`, `user.*`, `theme.*`.
@available(iOS 16.0, *)
public struct ConditionEvaluator {

    // MARK: - Public API

    /// Evaluate a component condition against the current rendering context.
    ///
    /// - Returns: `true` if the component should render (condition is nil or passes),
    ///            `false` if the condition fails.
    public static func evaluate(
        condition: ComponentCondition?,
        products: [ProductSlot]?,
        selectedProductIndex: Int,
        userAttributes: [String: Any]?,
        theme: PaywallTheme?
    ) -> Bool {
        guard let condition = condition else { return true }

        let context = buildContext(
            products: products,
            selectedProductIndex: selectedProductIndex,
            userAttributes: userAttributes,
            theme: theme
        )

        let resolved = FilterEngine.resolveField(context: context, fieldPath: condition.field)

        // Handle exists / not_exists operators
        switch condition.operator {
        case ConditionOperatorValue.exists:
            return resolved.found
        case ConditionOperatorValue.notExists:
            return !resolved.found
        default:
            break
        }

        // For other operators, if field is missing return false (safe default)
        guard resolved.found, let fieldValue = resolved.value else {
            return false
        }

        guard let conditionValue = condition.value else {
            return false
        }

        switch condition.operator {
        case ConditionOperatorValue.is:
            return isEqual(conditionValue, to: fieldValue)

        case ConditionOperatorValue.isNot:
            return !isEqual(conditionValue, to: fieldValue)

        case ConditionOperatorValue.contains:
            guard let str = fieldValue as? String else {
                return false
            }
            if case .string(let needle) = conditionValue {
                return str.contains(needle)
            }
            return false

        case ConditionOperatorValue.gt:
            return compareNumeric(fieldValue: fieldValue, conditionValue: conditionValue) { $0 > $1 }

        case ConditionOperatorValue.gte:
            return compareNumeric(fieldValue: fieldValue, conditionValue: conditionValue) { $0 >= $1 }

        case ConditionOperatorValue.lt:
            return compareNumeric(fieldValue: fieldValue, conditionValue: conditionValue) { $0 < $1 }

        case ConditionOperatorValue.lte:
            return compareNumeric(fieldValue: fieldValue, conditionValue: conditionValue) { $0 <= $1 }

        case ConditionOperatorValue.exists, ConditionOperatorValue.notExists:
            return false // handled above

        default:
            return false
        }
    }

    // MARK: - Context Building

    /// Build a flat context dictionary from the rendering parameters so that
    /// FilterEngine.resolveField can traverse dot-notation paths.
    static func buildContext(
        products: [ProductSlot]?,
        selectedProductIndex: Int,
        userAttributes: [String: Any]?,
        theme: PaywallTheme?
    ) -> [String: Any] {
        var context: [String: Any] = [:]

        // Products context
        if let products = products, !products.isEmpty {
            var productsDict: [String: Any] = [:]

            // Selected product
            if selectedProductIndex >= 0 && selectedProductIndex < products.count {
                productsDict["selected"] = productDict(products[selectedProductIndex])
            }

            // Slot-based lookups (e.g., products.primary, products.secondary)
            for product in products {
                productsDict[product.slot] = productDict(product)
            }

            context["products"] = productsDict
        }

        // User attributes
        if let attrs = userAttributes {
            context["user"] = attrs
        }

        // Theme properties
        if let theme = theme {
            context["theme"] = [
                "primary": theme.primary,
                "secondary": theme.secondary,
                "background": theme.background,
                "text_primary": theme.textPrimary,
                "text_secondary": theme.textSecondary,
                "accent": theme.accent,
                "surface": theme.surface,
                "corner_radius": theme.cornerRadius,
                "font_family": theme.fontFamily,
            ] as [String: Any]
        }

        return context
    }

    // MARK: - Helpers

    private static func productDict(_ product: ProductSlot) -> [String: Any] {
        var dict: [String: Any] = [
            "slot": product.slot,
            "label": product.label,
        ]
        if let pid = product.productId {
            dict["product_id"] = pid
        }
        return dict
    }

    private static func compareNumeric(
        fieldValue: Any,
        conditionValue: CodableValue,
        comparator: (Double, Double) -> Bool
    ) -> Bool {
        guard let filterNum = conditionValue.doubleValue else { return false }
        if let d = fieldValue as? Double {
            return comparator(d, filterNum)
        }
        if let i = fieldValue as? Int {
            return comparator(Double(i), filterNum)
        }
        return false
    }

    private static func isEqual(_ conditionValue: CodableValue, to fieldValue: Any) -> Bool {
        switch conditionValue {
        case .string(let s):
            return (fieldValue as? String) == s
        case .number(let n):
            if let d = fieldValue as? Double { return d == n }
            if let i = fieldValue as? Int { return Double(i) == n }
            return false
        case .bool(let b):
            return (fieldValue as? Bool) == b
        }
    }
}
