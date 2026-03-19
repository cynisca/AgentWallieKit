import Foundation

/// Evaluates audience filters against a context dictionary.
/// Mirrors the shared TypeScript filter-engine.
public enum FilterEngine {

    // MARK: - Public API

    /// Evaluate an array of audience filters against a context object.
    ///
    /// Filters are grouped by OR boundaries. Within each group, all conditions
    /// must be true (AND). If any group is true, the result is true.
    ///
    /// Example: [A, B(and), C(or), D(and)] => (A AND B) OR (C AND D)
    public static func evaluate(filters: [AudienceFilter], context: [String: Any]) -> Bool {
        if filters.isEmpty { return true }

        // Build groups split by OR
        var groups: [[AudienceFilter]] = []
        var currentGroup: [AudienceFilter] = []

        for (i, filter) in filters.enumerated() {
            if i == 0 {
                currentGroup.append(filter)
            } else if filter.conjunction == .or {
                groups.append(currentGroup)
                currentGroup = [filter]
            } else {
                // AND or nil continues current group
                currentGroup.append(filter)
            }
        }
        groups.append(currentGroup)

        // Any group passing means the whole filter set passes
        return groups.contains { group in
            group.allSatisfy { filter in evaluateSingle(filter: filter, context: context) }
        }
    }

    // MARK: - Internal

    /// Resolve a dot-notation field path against a context dictionary.
    static func resolveField(context: [String: Any], fieldPath: String) -> (found: Bool, value: Any?) {
        let parts = fieldPath.split(separator: ".").map(String.init)
        var current: Any = context

        for part in parts {
            guard let dict = current as? [String: Any], let next = dict[part] else {
                return (found: false, value: nil)
            }
            current = next
        }

        return (found: true, value: current)
    }

    /// Evaluate a single filter condition.
    static func evaluateSingle(filter: AudienceFilter, context: [String: Any]) -> Bool {
        let resolved = resolveField(context: context, fieldPath: filter.field)

        // Handle exists/not_exists first
        if filter.operator == .exists {
            return resolved.found
        }
        if filter.operator == .notExists {
            return !resolved.found
        }

        // For all other operators, if field is missing => false
        guard resolved.found, let fieldValue = resolved.value else {
            return false
        }

        switch filter.operator {
        case .is:
            return filter.value.isEqual(to: fieldValue)

        case .isNot:
            return !filter.value.isEqual(to: fieldValue)

        case .contains:
            guard let str = fieldValue as? String, let needle = filter.value.stringValue else {
                return false
            }
            return str.contains(needle)

        case .gt:
            return compareNumeric(fieldValue: fieldValue, filterValue: filter.value) { $0 > $1 }

        case .gte:
            return compareNumeric(fieldValue: fieldValue, filterValue: filter.value) { $0 >= $1 }

        case .lt:
            return compareNumeric(fieldValue: fieldValue, filterValue: filter.value) { $0 < $1 }

        case .lte:
            return compareNumeric(fieldValue: fieldValue, filterValue: filter.value) { $0 <= $1 }

        case .in:
            guard let arr = filter.value.arrayValue else { return false }
            if let s = fieldValue as? String { return arr.contains(s) }
            return false

        case .notIn:
            guard let arr = filter.value.arrayValue else { return false }
            if let s = fieldValue as? String { return !arr.contains(s) }
            return false

        case .exists, .notExists:
            return false // handled above
        }
    }

    private static func compareNumeric(fieldValue: Any, filterValue: FilterValue, comparator: (Double, Double) -> Bool) -> Bool {
        guard let filterNum = filterValue.doubleValue else { return false }
        if let d = fieldValue as? Double {
            return comparator(d, filterNum)
        }
        if let i = fieldValue as? Int {
            return comparator(Double(i), filterNum)
        }
        return false
    }
}
