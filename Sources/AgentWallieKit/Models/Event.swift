import Foundation

/// An analytics event to be sent to the backend.
public struct AnalyticsEvent: Codable, Sendable {
    public let id: String
    public let deviceId: String
    public let userId: String?
    public let eventName: String
    public let timestamp: Date
    public let properties: [String: AnyCodable]?
    public let campaignId: String?
    public let paywallId: String?

    public init(
        id: String = UUID().uuidString,
        deviceId: String,
        userId: String? = nil,
        eventName: String,
        timestamp: Date = Date(),
        properties: [String: AnyCodable]? = nil,
        campaignId: String? = nil,
        paywallId: String? = nil
    ) {
        self.id = id
        self.deviceId = deviceId
        self.userId = userId
        self.eventName = eventName
        self.timestamp = timestamp
        self.properties = properties
        self.campaignId = campaignId
        self.paywallId = paywallId
    }

    enum CodingKeys: String, CodingKey {
        case id
        case deviceId = "device_id"
        case userId = "user_id"
        case eventName = "event_name"
        case timestamp
        case properties
        case campaignId = "campaign_id"
        case paywallId = "paywall_id"
    }
}

// MARK: - AnyCodable

/// A type-erased Codable wrapper for heterogeneous dictionary values.
public struct AnyCodable: Codable, @unchecked Sendable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
