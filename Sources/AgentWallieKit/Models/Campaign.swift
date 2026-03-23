import Foundation

// MARK: - Campaign

public struct Campaign: Codable, Sendable {
    public let id: String
    public let name: String
    public let status: CampaignStatus
    public let placements: [Placement]
    public let audiences: [Audience]

    public init(
        id: String,
        name: String,
        status: CampaignStatus,
        placements: [Placement],
        audiences: [Audience]
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.placements = placements
        self.audiences = audiences
    }
}

public enum CampaignStatus: String, Codable, Sendable {
    case active
    case inactive
    case archived
}

// MARK: - Placement

public struct Placement: Codable, Sendable {
    public let id: String
    public let name: String
    public let type: PlacementType
    public let status: PlacementStatus

    public init(id: String, name: String, type: PlacementType, status: PlacementStatus) {
        self.id = id
        self.name = name
        self.type = type
        self.status = status
    }
}

public enum PlacementType: String, Codable, Sendable {
    case standard
    case custom
}

public enum PlacementStatus: String, Codable, Sendable {
    case active
    case paused
}

// MARK: - Audience

public struct Audience: Codable, Sendable {
    public let id: String
    public let name: String
    public let priorityOrder: Int
    public let filters: [AudienceFilter]
    public let entitlementCheck: String?
    public let frequencyCap: FrequencyCap?
    public let experiment: Experiment?

    public init(
        id: String,
        name: String,
        priorityOrder: Int,
        filters: [AudienceFilter],
        entitlementCheck: String? = nil,
        frequencyCap: FrequencyCap? = nil,
        experiment: Experiment? = nil
    ) {
        self.id = id
        self.name = name
        self.priorityOrder = priorityOrder
        self.filters = filters
        self.entitlementCheck = entitlementCheck
        self.frequencyCap = frequencyCap
        self.experiment = experiment
    }

    enum CodingKeys: String, CodingKey {
        case id, name, filters, experiment
        case priorityOrder = "priority_order"
        case entitlementCheck = "entitlement_check"
        case frequencyCap = "frequency_cap"
    }
}

// MARK: - Audience Filter

public struct AudienceFilter: Codable, Sendable {
    public let field: String
    public let `operator`: FilterOperator
    public let value: FilterValue
    public let conjunction: FilterConjunction?

    public init(field: String, operator: FilterOperator, value: FilterValue, conjunction: FilterConjunction? = nil) {
        self.field = field
        self.operator = `operator`
        self.value = value
        self.conjunction = conjunction
    }
}

public enum FilterOperator: String, Codable, Sendable {
    case `is`
    case isNot = "is_not"
    case contains
    case gt
    case gte
    case lt
    case lte
    case `in`
    case notIn = "not_in"
    case exists
    case notExists = "not_exists"
}

public enum FilterConjunction: String, Codable, Sendable {
    case and
    case or
}

/// A filter value that can be a string, number, bool, or array.
public enum FilterValue: Codable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case stringArray([String])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else if let d = try? container.decode(Double.self) {
            self = .double(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let arr = try? container.decode([String].self) {
            self = .stringArray(arr)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported filter value type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        case .double(let d): try container.encode(d)
        case .bool(let b): try container.encode(b)
        case .stringArray(let arr): try container.encode(arr)
        }
    }

    /// Compare this filter value to a runtime Any value using strict equality.
    public func isEqual(to other: Any) -> Bool {
        switch self {
        case .string(let s): return (other as? String) == s
        case .int(let i):
            if let oi = other as? Int { return oi == i }
            if let od = other as? Double { return od == Double(i) }
            return false
        case .double(let d):
            if let od = other as? Double { return od == d }
            if let oi = other as? Int { return Double(oi) == d }
            return false
        case .bool(let b): return (other as? Bool) == b
        case .stringArray(_): return false
        }
    }

    /// Returns the double representation if this is a numeric value.
    public var doubleValue: Double? {
        switch self {
        case .int(let i): return Double(i)
        case .double(let d): return d
        default: return nil
        }
    }

    /// Returns the string representation if this is a string value.
    public var stringValue: String? {
        switch self {
        case .string(let s): return s
        default: return nil
        }
    }

    /// Returns the array of strings if this is an array value.
    public var arrayValue: [String]? {
        switch self {
        case .stringArray(let arr): return arr
        default: return nil
        }
    }
}

// MARK: - Frequency Cap

public struct FrequencyCap: Codable, Sendable {
    public let type: FrequencyCapType
    public let limit: Int?

    public init(type: FrequencyCapType, limit: Int? = nil) {
        self.type = type
        self.limit = limit
    }

    public init(from decoder: Decoder) throws {
        // Handle both object format {"type":"once_per_session","limit":3}
        // and legacy string format "once_per_session"
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.type = try container.decode(FrequencyCapType.self, forKey: .type)
            self.limit = try container.decodeIfPresent(Int.self, forKey: .limit)
        } else {
            let single = try decoder.singleValueContainer()
            let raw = try single.decode(String.self)
            guard let parsed = FrequencyCapType(rawValue: raw) else {
                throw DecodingError.dataCorruptedError(
                    in: single,
                    debugDescription: "Unknown frequency cap type: \(raw)"
                )
            }
            self.type = parsed
            self.limit = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case type, limit
    }
}

public enum FrequencyCapType: String, Codable, Sendable {
    case oncePerSession = "once_per_session"
    case oncePerDay = "once_per_day"
    case nTimesTotal = "n_times_total"
    case unlimited
}

// MARK: - Experiment

public struct Experiment: Codable, Sendable {
    public let id: String
    public let variants: [ExperimentVariant]
    public let holdoutPercentage: Int
    public let status: ExperimentStatus

    public init(
        id: String,
        variants: [ExperimentVariant],
        holdoutPercentage: Int,
        status: ExperimentStatus
    ) {
        self.id = id
        self.variants = variants
        self.holdoutPercentage = holdoutPercentage
        self.status = status
    }

    enum CodingKeys: String, CodingKey {
        case id, variants, status
        case holdoutPercentage = "holdout_percentage"
    }
}

public enum ExperimentStatus: String, Codable, Sendable {
    case running
    case paused
    case completed
}

public struct ExperimentVariant: Codable, Sendable {
    public let id: String
    public let paywallId: String
    public let trafficPercentage: Int

    public init(id: String, paywallId: String, trafficPercentage: Int) {
        self.id = id
        self.paywallId = paywallId
        self.trafficPercentage = trafficPercentage
    }

    enum CodingKeys: String, CodingKey {
        case id
        case paywallId = "paywall_id"
        case trafficPercentage = "traffic_percentage"
    }
}
