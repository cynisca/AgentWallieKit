import AgentWallieKit
import Foundation

public enum JSONValue: Codable, Equatable, Sendable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }

    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    public var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    public var doubleValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    public var intValue: Int? {
        guard let value = doubleValue else { return nil }
        return Int(value)
    }

    public var objectValue: [String: JSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }

    public var arrayValue: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    public func toAny() -> Any {
        switch self {
        case .null:
            return NSNull()
        case .bool(let value):
            return value
        case .number(let value):
            return value
        case .string(let value):
            return value
        case .array(let value):
            return value.map { $0.toAny() }
        case .object(let value):
            return value.mapValues { $0.toAny() }
        }
    }

    public static func fromAny(_ value: Any) -> JSONValue {
        switch value {
        case is NSNull:
            return .null
        case let value as NSNumber:
            if CFGetTypeID(value) == CFBooleanGetTypeID() {
                return .bool(value.boolValue)
            }
            return .number(value.doubleValue)
        case let value as Int:
            return .number(Double(value))
        case let value as Double:
            return .number(value)
        case let value as Bool:
            return .bool(value)
        case let value as String:
            return .string(value)
        case let value as [Any]:
            return .array(value.map { .fromAny($0) })
        case let value as [String: Any]:
            return .object(value.mapValues { .fromAny($0) })
        default:
            return .string(String(describing: value))
        }
    }
}

public enum MCPError: Error, Sendable, LocalizedError {
    case invalidParams(String)
    case notFound(String)
    case conflict(String)

    public var errorDescription: String? {
        switch self {
        case .invalidParams(let message), .notFound(let message), .conflict(let message):
            return message
        }
    }
}

public enum ApplicationPlatform: String, Codable, Sendable {
    case ios
    case android
    case web
}

public struct OrganizationRecord: Codable, Sendable {
    public var id: String
    public var name: String
    public var createdAt: Date
}

public struct ProjectRecord: Codable, Sendable {
    public var id: String
    public var organizationId: String
    public var name: String
    public var metadata: [String: JSONValue]
    public var archived: Bool
    public var createdAt: Date
}

public struct ApplicationRecord: Codable, Sendable {
    public var id: String
    public var projectId: String
    public var name: String
    public var platform: ApplicationPlatform
    public var appId: String?
    public var bundleId: String?
    public var domain: String?
    public var apiKey: String
    public var metadata: [String: JSONValue]
    public var archived: Bool
    public var createdAt: Date
}

public struct EntitlementRecord: Codable, Sendable {
    public var id: String
    public var projectId: String
    public var identifier: String
    public var name: String?
    public var description: String?
    public var metadata: [String: JSONValue]
    public var productIds: [String]
    public var createdAt: Date
}

public struct ProductRecord: Codable, Sendable {
    public var id: String
    public var projectId: String
    public var identifier: String
    public var name: String?
    public var metadata: [String: JSONValue]
    public var entitlementIds: [String]
    public var price: PriceRecord?
    public var subscription: SubscriptionRecord?
    public var platform: String
    public var createdAt: Date

    public func asSDKProduct(entitlements: [EntitlementRecord]) -> AWProduct {
        let grantedEntitlements = entitlements
            .filter { entitlementIds.contains($0.id) }
            .map { $0.identifier }
        let displayPrice = price.map { "\($0.currency) \($0.amount)" }
        let displayPeriod = subscription.map {
            let count = $0.periodCount ?? 1
            return count == 1 ? $0.period.rawValue : "\(count) \($0.period.rawValue)"
        }
        return AWProduct(
            id: id,
            name: name ?? identifier,
            store: .apple,
            storeProductId: identifier,
            entitlements: grantedEntitlements,
            basePlanId: nil,
            offerIds: nil,
            displayPrice: displayPrice,
            displayPeriod: displayPeriod
        )
    }
}

public struct PriceRecord: Codable, Sendable {
    public var amount: Int
    public var currency: String
}

public struct SubscriptionRecord: Codable, Sendable {
    public enum Period: String, Codable, Sendable {
        case day
        case week
        case month
        case year
    }

    public var period: Period
    public var periodCount: Int?
    public var trialPeriodDays: Int?
}

public struct PaywallVersionRecord: Codable, Sendable {
    public var id: String
    public var schema: PaywallSchema
    public var createdAt: Date
    public var notes: String?
}

public struct PaywallRecord: Codable, Sendable {
    public var id: String
    public var applicationId: String
    public var name: String
    public var identifier: String
    public var productIds: [String]
    public var featureGating: String
    public var presentationStyle: String
    public var metadata: [String: JSONValue]
    public var versions: [PaywallVersionRecord]
    public var activeVersionId: String?
    public var archived: Bool
    public var createdAt: Date

    public var activeSchema: PaywallSchema? {
        guard let activeVersionId else { return versions.last?.schema }
        return versions.first(where: { $0.id == activeVersionId })?.schema
    }
}

public struct CampaignRecord: Codable, Sendable {
    public var id: String
    public var applicationId: String
    public var description: String
    public var notes: String?
    public var campaign: Campaign
    public var archived: Bool
    public var createdAt: Date
}

public struct WebhookEndpointRecord: Codable, Sendable {
    public var id: String
    public var projectId: String
    public var url: String
    public var description: String?
    public var filterTypes: [String]
    public var headers: [String: JSONValue]
    public var metadata: [String: JSONValue]
    public var disabled: Bool
    public var secret: String
    public var createdAt: Date
}

public struct EventRecord: Codable, Sendable {
    public var id: String
    public var projectId: String
    public var channel: String
    public var eventType: String
    public var payload: [String: JSONValue]
    public var createdAt: Date
}

public struct DeliveryAttemptRecord: Codable, Sendable {
    public var id: String
    public var eventId: String
    public var endpointId: String
    public var projectId: String
    public var status: Int
    public var statusCodeClass: Int
    public var attemptedAt: Date
}

public struct AssignmentRecord: Codable, Sendable {
    public var id: String
    public var applicationId: String
    public var userId: String
    public var experimentId: String
    public var assignment: StoredAssignment
}

public struct TemplateRecord: Codable, Sendable {
    public var id: String
    public var name: String
    public var category: String
    public var visibility: String
    public var schema: PaywallSchema
}

public struct RuntimeOptionsRecord: Codable, Sendable {
    public var defaultPresentation: String
    public var networkEnvironment: String
    public var customBaseURL: String?
    public var logLevel: String
    public var collectDeviceAttributes: Bool
    public var enableShakeDebugger: Bool

    public init(
        defaultPresentation: String = "modal",
        networkEnvironment: String = "production",
        customBaseURL: String? = nil,
        logLevel: String = "warn",
        collectDeviceAttributes: Bool = true,
        enableShakeDebugger: Bool = false
    ) {
        self.defaultPresentation = defaultPresentation
        self.networkEnvironment = networkEnvironment
        self.customBaseURL = customBaseURL
        self.logLevel = logLevel
        self.collectDeviceAttributes = collectDeviceAttributes
        self.enableShakeDebugger = enableShakeDebugger
    }
}

public struct RuntimeLogRecord: Codable, Sendable {
    public var level: String
    public var message: String
    public var createdAt: Date
}

public struct RuntimeDelegateEventRecord: Codable, Sendable {
    public var name: String
    public var payload: [String: JSONValue]
    public var createdAt: Date
}

public struct RuntimeTrackedEventRecord: Codable, Sendable {
    public var name: String
    public var properties: [String: JSONValue]
    public var createdAt: Date
}

public struct RuntimeSessionRecord: Codable, Sendable {
    public var id: String
    public var applicationId: String
    public var apiKey: String
    public var options: RuntimeOptionsRecord
    public var isConfigured: Bool
    public var configLoaded: Bool
    public var userId: String?
    public var deviceId: String
    public var seed: Int
    public var userAttributes: [String: JSONValue]
    public var subscriptionStatus: String
    public var entitlements: [String]
    public var currentPaywallId: String?
    public var currentCampaignId: String?
    public var currentExperimentId: String?
    public var currentVariantId: String?
    public var registeredPlacements: [String]
    public var previewVariants: [String: String]
    public var registeredViews: [String: [String: JSONValue]]
    public var logs: [RuntimeLogRecord]
    public var delegateEvents: [RuntimeDelegateEventRecord]
    public var trackedEvents: [RuntimeTrackedEventRecord]
    public var createdAt: Date

    public var effectiveUserId: String {
        userId ?? deviceId
    }
}

public struct MCPState: Codable, Sendable {
    public var version: Int = 1
    public var organizations: [OrganizationRecord] = []
    public var projects: [ProjectRecord] = []
    public var applications: [ApplicationRecord] = []
    public var entitlements: [EntitlementRecord] = []
    public var products: [ProductRecord] = []
    public var paywalls: [PaywallRecord] = []
    public var campaigns: [CampaignRecord] = []
    public var webhooks: [WebhookEndpointRecord] = []
    public var events: [EventRecord] = []
    public var deliveryAttempts: [DeliveryAttemptRecord] = []
    public var assignments: [AssignmentRecord] = []
    public var runtimeSessions: [RuntimeSessionRecord] = []
}

public final class AgentWallieMCPStore: @unchecked Sendable {
    public let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var state: MCPState

    public init(fileURL: URL) throws {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            state = try decoder.decode(MCPState.self, from: data)
        } else {
            state = MCPState()
            try save()
        }
    }

    public func snapshot() -> MCPState {
        state
    }

    public func mutate(_ block: (inout MCPState) throws -> Void) throws {
        try block(&state)
        try save()
    }

    private func save() throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try encoder.encode(state)
        try data.write(to: fileURL, options: .atomic)
    }
}

public enum TemplateCatalog {
    public static func templates() -> [TemplateRecord] {
        [
            TemplateRecord(
                id: "blank",
                name: "Blank",
                category: "starter",
                visibility: "public",
                schema: PaywallSchema(
                    version: "1",
                    name: "Blank Paywall",
                    settings: PaywallSettings(presentation: .modal),
                    theme: PaywallTheme(),
                    products: [],
                    components: []
                )
            ),
            TemplateRecord(
                id: "subscription_simple",
                name: "Simple Subscription",
                category: "subscription",
                visibility: "public",
                schema: PaywallSchema(
                    version: "1",
                    name: "Simple Subscription",
                    settings: PaywallSettings(presentation: .modal, backgroundColor: "#FFF8F0"),
                    theme: PaywallTheme(
                        background: "#FFF8F0",
                        primary: "#1F3A5F",
                        secondary: "#D96C4A",
                        textPrimary: "#1F2937",
                        textSecondary: "#6B7280",
                        accent: "#D96C4A",
                        surface: "#FFFFFF",
                        cornerRadius: 16,
                        fontFamily: "system",
                        fontFamilies: nil
                    ),
                    products: [
                        ProductSlot(slot: "primary", label: "Yearly"),
                        ProductSlot(slot: "secondary", label: "Monthly"),
                    ],
                    components: [
                        .text(TextComponentData(
                            id: "headline",
                            props: .init(content: "Upgrade to Premium", textStyle: "title1", alignment: "center")
                        )),
                        .text(TextComponentData(
                            id: "body",
                            props: .init(content: "Unlock all features with flexible plans.", textStyle: "body", alignment: "center")
                        )),
                        .productPicker(ProductPickerComponentData(
                            id: "plans",
                            props: .init(layout: "vertical", showSavingsBadge: true, savingsText: "Best Value", selectedBorderColor: "#D96C4A", showPrice: true)
                        )),
                        .ctaButton(CTAButtonComponentData(
                            id: "continue",
                            props: .init(text: "Continue", action: .purchase, product: "selected")
                        )),
                    ]
                )
            ),
        ]
    }
}

public enum AgentWallieMCPCompiler {
    public static func compiledConfig(state: MCPState, applicationId: String) throws -> SDKConfig {
        guard let application = state.applications.first(where: { $0.id == applicationId && !$0.archived }) else {
            throw MCPError.notFound("Application '\(applicationId)' not found")
        }

        let projectId = application.projectId
        let entitlements = state.entitlements.filter { $0.projectId == projectId }
        let products = state.products
            .filter { $0.projectId == projectId }
            .map { $0.asSDKProduct(entitlements: entitlements) }

        let paywalls = Dictionary(uniqueKeysWithValues: state.paywalls
            .filter { $0.applicationId == applicationId && !$0.archived }
            .compactMap { paywall -> (String, PaywallSchema)? in
                guard let schema = paywall.activeSchema else { return nil }
                return (paywall.id, schema)
            })

        let campaigns = state.campaigns
            .filter { $0.applicationId == applicationId && !$0.archived }
            .map { $0.campaign }

        return SDKConfig(campaigns: campaigns, paywalls: paywalls, products: products)
    }
}

public struct PlacementPreviewResult: Codable, Sendable {
    public var matched: Bool
    public var campaignId: String?
    public var audienceId: String?
    public var experimentId: String?
    public var variantId: String?
    public var paywallId: String?
    public var isHoldout: Bool
    public var config: SDKConfig?
}

public enum AgentWallieMCPEvaluator {
    public static func previewPlacement(
        state: inout MCPState,
        applicationId: String,
        placement: String,
        userId: String,
        userAttributes: [String: JSONValue],
        entitlements: Set<String>,
        eventParams: [String: JSONValue],
        includeConfig: Bool,
        persistAssignment: Bool,
        previewVariants: [String: String] = [:]
    ) throws -> PlacementPreviewResult {
        let config = try AgentWallieMCPCompiler.compiledConfig(state: state, applicationId: applicationId)
        let context = buildContext(
            userId: userId,
            userAttributes: userAttributes,
            eventParams: eventParams
        )

        for campaign in config.campaigns where campaign.status == .active {
            let hasPlacement = campaign.placements.contains { $0.name == placement && $0.status == .active }
            guard hasPlacement else { continue }

            for audience in campaign.audiences.sorted(by: { $0.priorityOrder < $1.priorityOrder }) {
                if let entitlementCheck = audience.entitlementCheck, entitlements.contains(entitlementCheck) {
                    continue
                }

                guard FilterEngine.evaluate(filters: audience.filters, context: context) else {
                    continue
                }

                guard let experiment = audience.experiment else {
                    return PlacementPreviewResult(
                        matched: true,
                        campaignId: campaign.id,
                        audienceId: audience.id,
                        experimentId: nil,
                        variantId: nil,
                        paywallId: nil,
                        isHoldout: false,
                        config: includeConfig ? config : nil
                    )
                }

                guard experiment.status == .running else {
                    return PlacementPreviewResult(
                        matched: true,
                        campaignId: campaign.id,
                        audienceId: audience.id,
                        experimentId: experiment.id,
                        variantId: nil,
                        paywallId: nil,
                        isHoldout: false,
                        config: includeConfig ? config : nil
                    )
                }

                if let forcedVariantId = previewVariants[experiment.id] {
                    guard let forcedVariant = experiment.variants.first(where: { $0.id == forcedVariantId }) else {
                        throw MCPError.invalidParams("Preview variant '\(forcedVariantId)' not found in experiment '\(experiment.id)'")
                    }
                    let stored = StoredAssignment(
                        variantId: forcedVariant.id,
                        paywallId: forcedVariant.paywallId,
                        isHoldout: false,
                        assignedAt: Date()
                    )
                    return PlacementPreviewResult(
                        matched: true,
                        campaignId: campaign.id,
                        audienceId: audience.id,
                        experimentId: experiment.id,
                        variantId: stored.variantId,
                        paywallId: stored.paywallId,
                        isHoldout: false,
                        config: includeConfig ? config : nil
                    )
                }

                if let existing = state.assignments.first(where: {
                    $0.applicationId == applicationId && $0.userId == userId && $0.experimentId == experiment.id
                }) {
                    return PlacementPreviewResult(
                        matched: true,
                        campaignId: campaign.id,
                        audienceId: audience.id,
                        experimentId: experiment.id,
                        variantId: existing.assignment.variantId,
                        paywallId: existing.assignment.paywallId,
                        isHoldout: existing.assignment.isHoldout,
                        config: includeConfig ? config : nil
                    )
                }

                let assignment = ExperimentAssignment.assignVariant(
                    userId: userId,
                    experimentId: experiment.id,
                    variants: experiment.variants,
                    holdoutPercentage: experiment.holdoutPercentage
                )
                let stored = StoredAssignment(
                    variantId: assignment?.variantId,
                    paywallId: assignment?.paywallId,
                    isHoldout: assignment == nil,
                    assignedAt: Date()
                )
                if persistAssignment {
                    state.assignments.append(AssignmentRecord(
                        id: UUID().uuidString,
                        applicationId: applicationId,
                        userId: userId,
                        experimentId: experiment.id,
                        assignment: stored
                    ))
                }
                return PlacementPreviewResult(
                    matched: true,
                    campaignId: campaign.id,
                    audienceId: audience.id,
                    experimentId: experiment.id,
                    variantId: stored.variantId,
                    paywallId: stored.paywallId,
                    isHoldout: stored.isHoldout,
                    config: includeConfig ? config : nil
                )
            }
        }

        return PlacementPreviewResult(
            matched: false,
            campaignId: nil,
            audienceId: nil,
            experimentId: nil,
            variantId: nil,
            paywallId: nil,
            isHoldout: false,
            config: includeConfig ? config : nil
        )
    }

    private static func buildContext(
        userId: String,
        userAttributes: [String: JSONValue],
        eventParams: [String: JSONValue]
    ) -> [String: Any] {
        let seed = hash("\(userId):seed") % 100
        var user: [String: Any] = [
            "id": userId,
            "seed": seed,
        ]
        for (key, value) in userAttributes {
            user[key] = value.toAny()
        }
        var context: [String: Any] = [
            "user": user,
            "device": [
                "id": "mcp-device",
                "platform": "ios",
                "os_version": "mcp",
            ],
            "platform": "ios",
            "os_version": "mcp",
        ]
        if !eventParams.isEmpty {
            context["event"] = ["params": eventParams.mapValues { $0.toAny() }]
        }
        return context
    }

    private static func hash(_ string: String) -> Int {
        var hash: UInt32 = 5381
        for char in string.utf8 {
            hash = (hash &<< 5) &+ hash &+ UInt32(char)
        }
        return Int(hash)
    }
}

public struct ToolDefinition: Codable, Sendable {
    public var name: String
    public var description: String
    public var inputSchema: [String: JSONValue]
}

public final class AgentWallieMCPService: @unchecked Sendable {
    public let store: AgentWallieMCPStore

    public init(store: AgentWallieMCPStore) {
        self.store = store
    }

    public func toolDefinitions() -> [ToolDefinition] {
        let names: [(String, String)] = [
            ("whoami", "Describe the local AgentWallie MCP server and state path."),
            ("create_organization", "Create an organization."),
            ("list_organizations", "List organizations."),
            ("create_project", "Create a project."),
            ("list_projects", "List projects."),
            ("get_project", "Get a project."),
            ("update_project", "Update a project."),
            ("archive_project", "Archive a project."),
            ("unarchive_project", "Unarchive a project."),
            ("create_application", "Create an application."),
            ("list_applications", "List applications."),
            ("get_application", "Get an application."),
            ("update_application", "Update an application."),
            ("archive_application", "Archive an application."),
            ("unarchive_application", "Unarchive an application."),
            ("rotate_application_api_key", "Rotate an application's API key."),
            ("create_entitlement", "Create an entitlement."),
            ("list_entitlements", "List entitlements."),
            ("get_entitlement", "Get an entitlement."),
            ("update_entitlement", "Update an entitlement."),
            ("delete_entitlement", "Delete an entitlement."),
            ("create_product", "Create a product."),
            ("list_products", "List products."),
            ("get_product", "Get a product."),
            ("update_product", "Update a product."),
            ("delete_product", "Delete a product."),
            ("list_templates", "List built-in paywall templates."),
            ("get_template", "Get a built-in paywall template."),
            ("create_paywall", "Create a paywall."),
            ("list_paywalls", "List paywalls."),
            ("get_paywall", "Get a paywall."),
            ("update_paywall", "Update or version a paywall schema."),
            ("validate_paywall", "Validate a paywall schema."),
            ("publish_paywall", "Publish a paywall version."),
            ("archive_paywall", "Archive a paywall."),
            ("unarchive_paywall", "Unarchive a paywall."),
            ("create_campaign", "Create a campaign."),
            ("list_campaigns", "List campaigns."),
            ("get_campaign", "Get a campaign."),
            ("update_campaign", "Update a campaign."),
            ("archive_campaign", "Archive a campaign."),
            ("unarchive_campaign", "Unarchive a campaign."),
            ("get_compiled_config", "Compile the exact SDK config for an application."),
            ("preview_placement", "Preview placement evaluation for a user context."),
            ("get_assignment", "Inspect a persisted experiment assignment."),
            ("reset_assignments", "Clear experiment assignments."),
            ("create_runtime_session", "Create and configure a runtime session for an application."),
            ("list_runtime_sessions", "List runtime sessions."),
            ("get_runtime_session", "Get runtime session state."),
            ("runtime_wait_for_config", "Wait for or inspect runtime config state."),
            ("runtime_identify", "Set the current runtime user id."),
            ("runtime_reset", "Reset the current runtime user and assignments."),
            ("runtime_set_subscription_state", "Set runtime subscription status and entitlements."),
            ("runtime_set_user_attributes", "Set runtime user attributes."),
            ("runtime_track_event", "Track a runtime event."),
            ("runtime_register_placement", "Evaluate and register a placement in the runtime session."),
            ("runtime_present_paywall", "Present a paywall directly in the runtime session."),
            ("runtime_get_paywall_for_placement", "Resolve a paywall for a placement without presenting it."),
            ("runtime_handle_deep_link", "Handle an AgentWallie deep link in the runtime session."),
            ("runtime_show_debugger", "Return the runtime debugger snapshot."),
            ("runtime_preview_variant", "Force a specific experiment variant in the runtime session."),
            ("runtime_clear_preview", "Clear a forced experiment variant preview."),
            ("runtime_register_view", "Register a custom view name in the runtime session."),
            ("runtime_is_view_registered", "Check whether a custom view name is registered."),
            ("record_event", "Record an analytics or webhook event."),
            ("list_events", "List events."),
            ("get_event", "Get an event."),
            ("list_event_attempts", "List webhook delivery attempts."),
            ("retry_event", "Retry webhook delivery."),
            ("create_webhook_endpoint", "Create a webhook endpoint."),
            ("list_webhook_endpoints", "List webhook endpoints."),
            ("get_webhook_endpoint", "Get a webhook endpoint."),
            ("update_webhook_endpoint", "Update a webhook endpoint."),
            ("delete_webhook_endpoint", "Delete a webhook endpoint."),
            ("rotate_webhook_secret", "Rotate a webhook secret."),
        ]
        return names.map { ToolDefinition(name: $0.0, description: $0.1, inputSchema: ["type": .string("object")]) }
    }

    public func callTool(name: String, arguments: [String: JSONValue]) throws -> JSONValue {
        switch name {
        case "whoami":
            return .object([
                "server": .string("AgentWallieMCPServer"),
                "state_path": .string(store.fileURL.path),
                "templates": .number(Double(TemplateCatalog.templates().count)),
            ])
        case "create_organization":
            let org = OrganizationRecord(id: UUID().uuidString, name: try require(arguments, "name"), createdAt: Date())
            try store.mutate { $0.organizations.append(org) }
            return encode(org)
        case "list_organizations":
            return encode(store.snapshot().organizations)
        case "create_project":
            let project = ProjectRecord(
                id: UUID().uuidString,
                organizationId: try require(arguments, "organization_id"),
                name: try require(arguments, "name"),
                metadata: arguments["metadata"]?.objectValue ?? [:],
                archived: false,
                createdAt: Date()
            )
            try store.mutate { state in
                guard state.organizations.contains(where: { $0.id == project.organizationId }) else {
                    throw MCPError.notFound("Organization '\(project.organizationId)' not found")
                }
                state.projects.append(project)
            }
            return encode(project)
        case "list_projects":
            var projects = store.snapshot().projects
            if let organizationId = arguments["organization_id"]?.stringValue {
                projects = projects.filter { $0.organizationId == organizationId }
            }
            if arguments["archived"]?.boolValue != true {
                projects = projects.filter { !$0.archived }
            }
            return encode(projects)
        case "get_project":
            return encode(try requireProject(id: try require(arguments, "id")))
        case "update_project":
            let id = try require(arguments, "id")
            var updated: ProjectRecord?
            try store.mutate { state in
                guard let index = state.projects.firstIndex(where: { $0.id == id }) else {
                    throw MCPError.notFound("Project '\(id)' not found")
                }
                if let name = arguments["name"]?.stringValue { state.projects[index].name = name }
                if let metadata = arguments["metadata"]?.objectValue { state.projects[index].metadata = metadata }
                updated = state.projects[index]
            }
            return encode(updated!)
        case "archive_project", "unarchive_project":
            let archived = name == "archive_project"
            let id = try require(arguments, "id")
            var updated: ProjectRecord?
            try store.mutate { state in
                guard let index = state.projects.firstIndex(where: { $0.id == id }) else {
                    throw MCPError.notFound("Project '\(id)' not found")
                }
                state.projects[index].archived = archived
                updated = state.projects[index]
            }
            return encode(updated!)
        case "create_application":
            let projectId = try require(arguments, "project_id")
            let platform = try decodeEnum(ApplicationPlatform.self, value: requireValue(arguments, "platform"))
            let app = ApplicationRecord(
                id: UUID().uuidString,
                projectId: projectId,
                name: try require(arguments, "name"),
                platform: platform,
                appId: arguments["app_id"]?.stringValue,
                bundleId: arguments["bundle_id"]?.stringValue,
                domain: arguments["domain"]?.stringValue,
                apiKey: "pk_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))",
                metadata: arguments["metadata"]?.objectValue ?? [:],
                archived: false,
                createdAt: Date()
            )
            try store.mutate { state in
                guard state.projects.contains(where: { $0.id == projectId }) else {
                    throw MCPError.notFound("Project '\(projectId)' not found")
                }
                state.applications.append(app)
            }
            return encode(app)
        case "list_applications":
            var applications = store.snapshot().applications
            if let projectId = arguments["project_id"]?.stringValue {
                applications = applications.filter { $0.projectId == projectId }
            }
            if arguments["archived"]?.boolValue != true {
                applications = applications.filter { !$0.archived }
            }
            return encode(applications)
        case "get_application":
            return encode(try requireApplication(id: try require(arguments, "id")))
        case "update_application":
            let id = try require(arguments, "id")
            var updated: ApplicationRecord?
            try store.mutate { state in
                guard let index = state.applications.firstIndex(where: { $0.id == id }) else {
                    throw MCPError.notFound("Application '\(id)' not found")
                }
                if let name = arguments["name"]?.stringValue { state.applications[index].name = name }
                if let appId = arguments["app_id"]?.stringValue { state.applications[index].appId = appId }
                if let bundleId = arguments["bundle_id"]?.stringValue { state.applications[index].bundleId = bundleId }
                if let domain = arguments["domain"]?.stringValue { state.applications[index].domain = domain }
                if let metadata = arguments["metadata"]?.objectValue { state.applications[index].metadata = metadata }
                updated = state.applications[index]
            }
            return encode(updated!)
        case "archive_application", "unarchive_application":
            let archived = name == "archive_application"
            let id = try require(arguments, "id")
            var updated: ApplicationRecord?
            try store.mutate { state in
                guard let index = state.applications.firstIndex(where: { $0.id == id }) else {
                    throw MCPError.notFound("Application '\(id)' not found")
                }
                state.applications[index].archived = archived
                updated = state.applications[index]
            }
            return encode(updated!)
        case "rotate_application_api_key":
            let id = try require(arguments, "id")
            var updated: ApplicationRecord?
            try store.mutate { state in
                guard let index = state.applications.firstIndex(where: { $0.id == id }) else {
                    throw MCPError.notFound("Application '\(id)' not found")
                }
                state.applications[index].apiKey = "pk_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
                updated = state.applications[index]
            }
            return encode(updated!)
        case "create_entitlement":
            let entitlement = EntitlementRecord(
                id: UUID().uuidString,
                projectId: try require(arguments, "project_id"),
                identifier: try require(arguments, "identifier"),
                name: arguments["name"]?.stringValue,
                description: arguments["description"]?.stringValue,
                metadata: arguments["metadata"]?.objectValue ?? [:],
                productIds: arguments["products"]?.arrayValue?.compactMap { $0.stringValue } ?? [],
                createdAt: Date()
            )
            try store.mutate { state in
                guard state.projects.contains(where: { $0.id == entitlement.projectId }) else {
                    throw MCPError.notFound("Project '\(entitlement.projectId)' not found")
                }
                state.entitlements.append(entitlement)
            }
            return encode(entitlement)
        case "list_entitlements":
            let projectId = try require(arguments, "project_id")
            return encode(store.snapshot().entitlements.filter { $0.projectId == projectId })
        case "get_entitlement":
            let id = try require(arguments, "id")
            guard let entitlement = store.snapshot().entitlements.first(where: { $0.id == id }) else {
                throw MCPError.notFound("Entitlement '\(id)' not found")
            }
            return encode(entitlement)
        case "update_entitlement":
            let id = try require(arguments, "id")
            var updated: EntitlementRecord?
            try store.mutate { state in
                guard let index = state.entitlements.firstIndex(where: { $0.id == id }) else {
                    throw MCPError.notFound("Entitlement '\(id)' not found")
                }
                if let name = arguments["name"]?.stringValue { state.entitlements[index].name = name }
                if arguments.keys.contains("description"), let description = arguments["description"]?.stringValue {
                    state.entitlements[index].description = description
                }
                if let metadata = arguments["metadata"]?.objectValue { state.entitlements[index].metadata = metadata }
                if let products = arguments["products"]?.arrayValue?.compactMap({ $0.stringValue }) { state.entitlements[index].productIds = products }
                updated = state.entitlements[index]
            }
            return encode(updated!)
        case "delete_entitlement":
            let id = try require(arguments, "id")
            try store.mutate { state in
                state.entitlements.removeAll { $0.id == id }
                for index in state.products.indices {
                    state.products[index].entitlementIds.removeAll { $0 == id }
                }
            }
            return .object(["deleted": .bool(true)])
        case "create_product":
            let product = ProductRecord(
                id: UUID().uuidString,
                projectId: try require(arguments, "project_id"),
                identifier: try require(arguments, "identifier"),
                name: arguments["name"]?.stringValue,
                metadata: arguments["metadata"]?.objectValue ?? [:],
                entitlementIds: arguments["entitlements"]?.arrayValue?.compactMap { $0.stringValue } ?? [],
                price: try arguments["price"].map { try decode(PriceRecord.self, from: $0) },
                subscription: try arguments["subscription"].map { try decode(SubscriptionRecord.self, from: $0) },
                platform: arguments["platform"]?.stringValue ?? "ios",
                createdAt: Date()
            )
            try store.mutate { state in
                guard state.projects.contains(where: { $0.id == product.projectId }) else {
                    throw MCPError.notFound("Project '\(product.projectId)' not found")
                }
                state.products.append(product)
            }
            return encode(product)
        case "list_products":
            let projectId = try require(arguments, "project_id")
            return encode(store.snapshot().products.filter { $0.projectId == projectId })
        case "get_product":
            let id = try require(arguments, "id")
            guard let product = store.snapshot().products.first(where: { $0.id == id }) else {
                throw MCPError.notFound("Product '\(id)' not found")
            }
            return encode(product)
        case "update_product":
            let id = try require(arguments, "id")
            var updated: ProductRecord?
            try store.mutate { state in
                guard let index = state.products.firstIndex(where: { $0.id == id }) else {
                    throw MCPError.notFound("Product '\(id)' not found")
                }
                if let name = arguments["name"]?.stringValue { state.products[index].name = name }
                if let metadata = arguments["metadata"]?.objectValue { state.products[index].metadata = metadata }
                if let entitlements = arguments["entitlements"]?.arrayValue?.compactMap({ $0.stringValue }) { state.products[index].entitlementIds = entitlements }
                if let price = arguments["price"] { state.products[index].price = try decode(PriceRecord.self, from: price) }
                if let subscription = arguments["subscription"] { state.products[index].subscription = try decode(SubscriptionRecord.self, from: subscription) }
                updated = state.products[index]
            }
            return encode(updated!)
        case "delete_product":
            let id = try require(arguments, "id")
            try store.mutate { state in
                state.products.removeAll { $0.id == id }
                for index in state.entitlements.indices {
                    state.entitlements[index].productIds.removeAll { $0 == id }
                }
                for index in state.paywalls.indices {
                    state.paywalls[index].productIds.removeAll { $0 == id }
                }
            }
            return .object(["deleted": .bool(true)])
        case "list_templates":
            var templates = TemplateCatalog.templates()
            if let category = arguments["category"]?.stringValue {
                templates = templates.filter { $0.category == category }
            }
            return encode(templates)
        case "get_template":
            let id = try require(arguments, "id")
            guard let template = TemplateCatalog.templates().first(where: { $0.id == id }) else {
                throw MCPError.notFound("Template '\(id)' not found")
            }
            return encode(template)
        case "create_paywall":
            let applicationId = try require(arguments, "application_id")
            let nameValue = try require(arguments, "name")
            let templateId = arguments["template"]?.stringValue ?? "blank"
            guard let template = TemplateCatalog.templates().first(where: { $0.id == templateId }) else {
                throw MCPError.notFound("Template '\(templateId)' not found")
            }
            let schema = try arguments["schema"].map { try decode(PaywallSchema.self, from: $0) } ?? template.schema
            let version = PaywallVersionRecord(id: UUID().uuidString, schema: schema, createdAt: Date(), notes: "Initial version")
            let paywall = PaywallRecord(
                id: UUID().uuidString,
                applicationId: applicationId,
                name: nameValue,
                identifier: arguments["identifier"]?.stringValue ?? slugify(nameValue),
                productIds: arguments["products"]?.arrayValue?.compactMap { $0.stringValue } ?? [],
                featureGating: arguments["feature_gating"]?.stringValue ?? "non_gated",
                presentationStyle: arguments["presentation_style"]?.stringValue ?? "fullscreen",
                metadata: arguments["metadata"]?.objectValue ?? [:],
                versions: [version],
                activeVersionId: version.id,
                archived: false,
                createdAt: Date()
            )
            try validatePaywallSchema(paywallSchema: schema, applicationId: applicationId)
            try store.mutate { state in
                guard state.applications.contains(where: { $0.id == applicationId }) else {
                    throw MCPError.notFound("Application '\(applicationId)' not found")
                }
                state.paywalls.append(paywall)
            }
            return encode(paywall)
        case "list_paywalls":
            let applicationId = try require(arguments, "application_id")
            var paywalls = store.snapshot().paywalls.filter { $0.applicationId == applicationId }
            if arguments["archived"]?.boolValue != true {
                paywalls = paywalls.filter { !$0.archived }
            }
            return encode(paywalls)
        case "get_paywall":
            let id = try require(arguments, "id")
            guard let paywall = store.snapshot().paywalls.first(where: { $0.id == id }) else {
                throw MCPError.notFound("Paywall '\(id)' not found")
            }
            return encode(paywall)
        case "update_paywall":
            let id = try require(arguments, "id")
            var updated: PaywallRecord?
            try store.mutate { state in
                guard let index = state.paywalls.firstIndex(where: { $0.id == id }) else {
                    throw MCPError.notFound("Paywall '\(id)' not found")
                }
                if let name = arguments["name"]?.stringValue { state.paywalls[index].name = name }
                if let identifier = arguments["identifier"]?.stringValue { state.paywalls[index].identifier = identifier }
                if let products = arguments["products"]?.arrayValue?.compactMap({ $0.stringValue }) { state.paywalls[index].productIds = products }
                if let featureGating = arguments["feature_gating"]?.stringValue { state.paywalls[index].featureGating = featureGating }
                if let presentationStyle = arguments["presentation_style"]?.stringValue { state.paywalls[index].presentationStyle = presentationStyle }
                if let metadata = arguments["metadata"]?.objectValue { state.paywalls[index].metadata = metadata }
                if let schemaValue = arguments["schema"] {
                    let schema = try decode(PaywallSchema.self, from: schemaValue)
                    try validatePaywallSchema(paywallSchema: schema, applicationId: state.paywalls[index].applicationId, state: state)
                    let version = PaywallVersionRecord(
                        id: UUID().uuidString,
                        schema: schema,
                        createdAt: Date(),
                        notes: arguments["notes"]?.stringValue
                    )
                    state.paywalls[index].versions.append(version)
                    if arguments["publish"]?.boolValue == true {
                        state.paywalls[index].activeVersionId = version.id
                    }
                }
                updated = state.paywalls[index]
            }
            return encode(updated!)
        case "validate_paywall":
            let applicationId = arguments["application_id"]?.stringValue
            let schema = try decode(PaywallSchema.self, from: requireValue(arguments, "schema"))
            try validatePaywallSchema(paywallSchema: schema, applicationId: applicationId)
            return .object(["valid": .bool(true)])
        case "publish_paywall":
            let id = try require(arguments, "id")
            let versionId = arguments["version_id"]?.stringValue
            var updated: PaywallRecord?
            try store.mutate { state in
                guard let index = state.paywalls.firstIndex(where: { $0.id == id }) else {
                    throw MCPError.notFound("Paywall '\(id)' not found")
                }
                let candidate = versionId ?? state.paywalls[index].versions.last?.id
                guard let candidate, state.paywalls[index].versions.contains(where: { $0.id == candidate }) else {
                    throw MCPError.notFound("Version not found for paywall '\(id)'")
                }
                state.paywalls[index].activeVersionId = candidate
                updated = state.paywalls[index]
            }
            return encode(updated!)
        case "archive_paywall", "unarchive_paywall":
            let archived = name == "archive_paywall"
            let id = try require(arguments, "id")
            var updated: PaywallRecord?
            try store.mutate { state in
                guard let index = state.paywalls.firstIndex(where: { $0.id == id }) else {
                    throw MCPError.notFound("Paywall '\(id)' not found")
                }
                state.paywalls[index].archived = archived
                updated = state.paywalls[index]
            }
            return encode(updated!)
        case "create_campaign":
            let applicationId = try require(arguments, "application_id")
            let campaign = try decode(Campaign.self, from: requireValue(arguments, "campaign"))
            try validateCampaign(campaign: campaign, applicationId: applicationId)
            let record = CampaignRecord(
                id: campaign.id,
                applicationId: applicationId,
                description: arguments["description"]?.stringValue ?? campaign.name,
                notes: arguments["notes"]?.stringValue,
                campaign: campaign,
                archived: false,
                createdAt: Date()
            )
            try store.mutate { $0.campaigns.append(record) }
            return encode(record)
        case "list_campaigns":
            let applicationId = try require(arguments, "application_id")
            var campaigns = store.snapshot().campaigns.filter { $0.applicationId == applicationId }
            if arguments["archived"]?.boolValue != true {
                campaigns = campaigns.filter { !$0.archived }
            }
            return encode(campaigns)
        case "get_campaign":
            let id = try require(arguments, "id")
            guard let campaign = store.snapshot().campaigns.first(where: { $0.id == id }) else {
                throw MCPError.notFound("Campaign '\(id)' not found")
            }
            return encode(campaign)
        case "update_campaign":
            let id = try require(arguments, "id")
            var updated: CampaignRecord?
            try store.mutate { state in
                guard let index = state.campaigns.firstIndex(where: { $0.id == id }) else {
                    throw MCPError.notFound("Campaign '\(id)' not found")
                }
                if let description = arguments["description"]?.stringValue { state.campaigns[index].description = description }
                if arguments.keys.contains("notes") { state.campaigns[index].notes = arguments["notes"]?.stringValue }
                if let campaignValue = arguments["campaign"] {
                    let campaign = try decode(Campaign.self, from: campaignValue)
                    try validateCampaign(campaign: campaign, applicationId: state.campaigns[index].applicationId, state: state)
                    state.campaigns[index].campaign = campaign
                }
                updated = state.campaigns[index]
            }
            return encode(updated!)
        case "archive_campaign", "unarchive_campaign":
            let archived = name == "archive_campaign"
            let id = try require(arguments, "id")
            var updated: CampaignRecord?
            try store.mutate { state in
                guard let index = state.campaigns.firstIndex(where: { $0.id == id }) else {
                    throw MCPError.notFound("Campaign '\(id)' not found")
                }
                state.campaigns[index].archived = archived
                state.campaigns[index].campaign = Campaign(
                    id: state.campaigns[index].campaign.id,
                    name: state.campaigns[index].campaign.name,
                    status: archived ? .archived : .inactive,
                    placements: state.campaigns[index].campaign.placements,
                    audiences: state.campaigns[index].campaign.audiences
                )
                updated = state.campaigns[index]
            }
            return encode(updated!)
        case "get_compiled_config":
            let config = try AgentWallieMCPCompiler.compiledConfig(state: store.snapshot(), applicationId: try require(arguments, "application_id"))
            return encode(config)
        case "preview_placement":
            let applicationId = try require(arguments, "application_id")
            let placement = try require(arguments, "placement")
            let userId = try require(arguments, "user_id")
            let includeConfig = arguments["include_config"]?.boolValue ?? false
            let persistAssignment = arguments["persist_assignment"]?.boolValue ?? true
            var result: PlacementPreviewResult?
            try store.mutate { state in
                result = try AgentWallieMCPEvaluator.previewPlacement(
                    state: &state,
                    applicationId: applicationId,
                    placement: placement,
                    userId: userId,
                    userAttributes: arguments["user_attributes"]?.objectValue ?? [:],
                    entitlements: Set(arguments["entitlements"]?.arrayValue?.compactMap { $0.stringValue } ?? []),
                    eventParams: arguments["event_params"]?.objectValue ?? [:],
                    includeConfig: includeConfig,
                    persistAssignment: persistAssignment
                )
            }
            return encode(result!)
        case "get_assignment":
            let applicationId = try require(arguments, "application_id")
            let userId = try require(arguments, "user_id")
            let experimentId = try require(arguments, "experiment_id")
            guard let assignment = store.snapshot().assignments.first(where: {
                $0.applicationId == applicationId && $0.userId == userId && $0.experimentId == experimentId
            }) else {
                throw MCPError.notFound("Assignment not found")
            }
            return encode(assignment)
        case "reset_assignments":
            let applicationId = try require(arguments, "application_id")
            let userId = arguments["user_id"]?.stringValue
            let experimentId = arguments["experiment_id"]?.stringValue
            try store.mutate { state in
                state.assignments.removeAll { assignment in
                    guard assignment.applicationId == applicationId else { return false }
                    if let userId, assignment.userId != userId { return false }
                    if let experimentId, assignment.experimentId != experimentId { return false }
                    return true
                }
            }
            return .object(["cleared": .bool(true)])
        case "create_runtime_session":
            let applicationId = try require(arguments, "application_id")
            var session: RuntimeSessionRecord?
            try store.mutate { state in
                guard let app = state.applications.first(where: { $0.id == applicationId && !$0.archived }) else {
                    throw MCPError.notFound("Application '\(applicationId)' not found")
                }
                let options = try arguments["options"].map { try decode(RuntimeOptionsRecord.self, from: $0) } ?? RuntimeOptionsRecord()
                session = RuntimeSessionRecord(
                    id: UUID().uuidString,
                    applicationId: applicationId,
                    apiKey: app.apiKey,
                    options: options,
                    isConfigured: true,
                    configLoaded: true,
                    userId: nil,
                    deviceId: UUID().uuidString,
                    seed: Int.random(in: 0...99),
                    userAttributes: [:],
                    subscriptionStatus: "unknown",
                    entitlements: [],
                    currentPaywallId: nil,
                    currentCampaignId: nil,
                    currentExperimentId: nil,
                    currentVariantId: nil,
                    registeredPlacements: [],
                    previewVariants: [:],
                    registeredViews: [:],
                    logs: [],
                    delegateEvents: [],
                    trackedEvents: [],
                    createdAt: Date()
                )
                appendLog(to: &session!, level: options.logLevel, message: "Configured runtime session for application \(applicationId)")
                state.runtimeSessions.append(session!)
            }
            return encode(session!)
        case "list_runtime_sessions":
            var sessions = store.snapshot().runtimeSessions
            if let applicationId = arguments["application_id"]?.stringValue {
                sessions = sessions.filter { $0.applicationId == applicationId }
            }
            return encode(sessions)
        case "get_runtime_session":
            return encode(try requireRuntimeSession(id: try require(arguments, "id")))
        case "runtime_wait_for_config":
            let sessionId = try require(arguments, "id")
            let includeConfig = arguments["include_config"]?.boolValue ?? false
            let session = try requireRuntimeSession(id: sessionId)
            var result: [String: JSONValue] = [
                "ready": .bool(session.configLoaded),
                "session": encode(session),
            ]
            if includeConfig {
                result["config"] = encode(try AgentWallieMCPCompiler.compiledConfig(state: store.snapshot(), applicationId: session.applicationId))
            }
            return .object(result)
        case "runtime_identify":
            let sessionId = try require(arguments, "id")
            let userId = try require(arguments, "user_id")
            var session: RuntimeSessionRecord?
            try store.mutate { state in
                let index = try requireRuntimeSessionIndex(id: sessionId, state: state)
                state.runtimeSessions[index].userId = userId
                appendLog(to: &state.runtimeSessions[index], level: state.runtimeSessions[index].options.logLevel, message: "Identified user: \(userId)")
                session = state.runtimeSessions[index]
            }
            return encode(session!)
        case "runtime_reset":
            let sessionId = try require(arguments, "id")
            var session: RuntimeSessionRecord?
            try store.mutate { state in
                let index = try requireRuntimeSessionIndex(id: sessionId, state: state)
                let effectiveUserId = state.runtimeSessions[index].effectiveUserId
                state.assignments.removeAll { $0.applicationId == state.runtimeSessions[index].applicationId && $0.userId == effectiveUserId }
                state.runtimeSessions[index].userId = nil
                state.runtimeSessions[index].deviceId = UUID().uuidString
                state.runtimeSessions[index].seed = Int.random(in: 0...99)
                state.runtimeSessions[index].userAttributes = [:]
                state.runtimeSessions[index].entitlements = []
                state.runtimeSessions[index].subscriptionStatus = "unknown"
                state.runtimeSessions[index].currentPaywallId = nil
                state.runtimeSessions[index].currentCampaignId = nil
                state.runtimeSessions[index].currentExperimentId = nil
                state.runtimeSessions[index].currentVariantId = nil
                appendLog(to: &state.runtimeSessions[index], level: state.runtimeSessions[index].options.logLevel, message: "Runtime session reset")
                session = state.runtimeSessions[index]
            }
            return encode(session!)
        case "runtime_set_subscription_state":
            let sessionId = try require(arguments, "id")
            let status = try require(arguments, "status")
            let entitlements = arguments["entitlements"]?.arrayValue?.compactMap { $0.stringValue } ?? []
            var session: RuntimeSessionRecord?
            try store.mutate { state in
                let index = try requireRuntimeSessionIndex(id: sessionId, state: state)
                state.runtimeSessions[index].subscriptionStatus = status
                state.runtimeSessions[index].entitlements = entitlements
                appendDelegateEvent(
                    to: &state.runtimeSessions[index],
                    name: "didUpdateSubscriptionStatus",
                    payload: [
                        "status": .string(status),
                        "entitlements": .array(entitlements.map(JSONValue.string)),
                    ]
                )
                appendLog(to: &state.runtimeSessions[index], level: state.runtimeSessions[index].options.logLevel, message: "Updated subscription state")
                session = state.runtimeSessions[index]
            }
            return encode(session!)
        case "runtime_set_user_attributes":
            let sessionId = try require(arguments, "id")
            let attributes = arguments["attributes"]?.objectValue ?? [:]
            var session: RuntimeSessionRecord?
            try store.mutate { state in
                let index = try requireRuntimeSessionIndex(id: sessionId, state: state)
                for (key, value) in attributes {
                    state.runtimeSessions[index].userAttributes[key] = value
                }
                appendLog(to: &state.runtimeSessions[index], level: state.runtimeSessions[index].options.logLevel, message: "Updated user attributes")
                session = state.runtimeSessions[index]
            }
            return encode(session!)
        case "runtime_track_event":
            let sessionId = try require(arguments, "id")
            let eventName = try require(arguments, "name")
            let properties = arguments["properties"]?.objectValue ?? [:]
            var session: RuntimeSessionRecord?
            try store.mutate { state in
                let index = try requireRuntimeSessionIndex(id: sessionId, state: state)
                state.runtimeSessions[index].trackedEvents.append(RuntimeTrackedEventRecord(name: eventName, properties: properties, createdAt: Date()))
                appendLog(to: &state.runtimeSessions[index], level: state.runtimeSessions[index].options.logLevel, message: "Tracked event '\(eventName)'")
                session = state.runtimeSessions[index]
            }
            return encode(session!)
        case "runtime_register_placement":
            let sessionId = try require(arguments, "id")
            let placement = try require(arguments, "placement")
            let runHandlerOnNoMatch = arguments["run_handler_on_no_match"]?.boolValue ?? true
            var result: [String: JSONValue] = [:]
            try store.mutate { state in
                let index = try requireRuntimeSessionIndex(id: sessionId, state: state)
                if !state.runtimeSessions[index].registeredPlacements.contains(placement) {
                    state.runtimeSessions[index].registeredPlacements.append(placement)
                }
                let preview = try AgentWallieMCPEvaluator.previewPlacement(
                    state: &state,
                    applicationId: state.runtimeSessions[index].applicationId,
                    placement: placement,
                    userId: state.runtimeSessions[index].effectiveUserId,
                    userAttributes: state.runtimeSessions[index].userAttributes,
                    entitlements: Set(state.runtimeSessions[index].entitlements),
                    eventParams: [:],
                    includeConfig: true,
                    persistAssignment: true,
                    previewVariants: state.runtimeSessions[index].previewVariants
                )
                result["preview"] = encode(preview)
                if preview.matched, let paywallId = preview.paywallId {
                    try presentRuntimePaywall(
                        state: &state,
                        sessionIndex: index,
                        paywallId: paywallId,
                        campaignId: preview.campaignId,
                        experimentId: preview.experimentId,
                        variantId: preview.variantId
                    )
                    result["presented"] = .bool(true)
                } else {
                    result["presented"] = .bool(false)
                    result["handlerInvoked"] = .bool(runHandlerOnNoMatch || preview.isHoldout)
                }
                result["session"] = encode(state.runtimeSessions[index])
            }
            return .object(result)
        case "runtime_present_paywall":
            let sessionId = try require(arguments, "id")
            let paywallId = try require(arguments, "paywall_id")
            var session: RuntimeSessionRecord?
            try store.mutate { state in
                let index = try requireRuntimeSessionIndex(id: sessionId, state: state)
                try presentRuntimePaywall(state: &state, sessionIndex: index, paywallId: paywallId, campaignId: nil, experimentId: nil, variantId: nil)
                session = state.runtimeSessions[index]
            }
            return encode(session!)
        case "runtime_get_paywall_for_placement":
            let sessionId = try require(arguments, "id")
            let placement = try require(arguments, "placement")
            let session = try requireRuntimeSession(id: sessionId)
            var state = store.snapshot()
            let preview = try AgentWallieMCPEvaluator.previewPlacement(
                state: &state,
                applicationId: session.applicationId,
                placement: placement,
                userId: session.effectiveUserId,
                userAttributes: session.userAttributes,
                entitlements: Set(session.entitlements),
                eventParams: [:],
                includeConfig: true,
                persistAssignment: false,
                previewVariants: session.previewVariants
            )
            guard preview.matched, !preview.isHoldout, let paywallId = preview.paywallId,
                  let schema = preview.config?.paywalls[paywallId] else {
                throw MCPError.notFound("No paywall found for placement '\(placement)'")
            }
            return .object([
                "paywall_id": .string(paywallId),
                "schema": encode(schema),
                "preview": encode(preview),
            ])
        case "runtime_handle_deep_link":
            let sessionId = try require(arguments, "id")
            let urlString = try require(arguments, "url")
            guard let url = URL(string: urlString),
                  url.scheme == "agentwallie",
                  url.host == "paywall",
                  let paywallId = url.pathComponents.dropFirst().first else {
                throw MCPError.invalidParams("Unsupported deep link '\(urlString)'")
            }
            var session: RuntimeSessionRecord?
            try store.mutate { state in
                let index = try requireRuntimeSessionIndex(id: sessionId, state: state)
                try presentRuntimePaywall(state: &state, sessionIndex: index, paywallId: paywallId, campaignId: nil, experimentId: nil, variantId: nil)
                appendLog(to: &state.runtimeSessions[index], level: state.runtimeSessions[index].options.logLevel, message: "Handled deep link \(urlString)")
                session = state.runtimeSessions[index]
            }
            return encode(session!)
        case "runtime_show_debugger":
            let session = try requireRuntimeSession(id: try require(arguments, "id"))
            let state = store.snapshot()
            let config = try AgentWallieMCPCompiler.compiledConfig(state: state, applicationId: session.applicationId)
            let assignments = state.assignments.filter { $0.applicationId == session.applicationId && $0.userId == session.effectiveUserId }
            return .object([
                "status": .object([
                    "is_configured": .bool(session.isConfigured),
                    "config_loaded": .bool(session.configLoaded),
                    "api_key": .string(session.apiKey),
                    "base_url": .string(resolveBaseURL(options: session.options)),
                ]),
                "user": .object([
                    "user_id": session.userId.map(JSONValue.string) ?? .null,
                    "device_id": .string(session.deviceId),
                    "seed": .number(Double(session.seed)),
                    "attributes": .object(session.userAttributes),
                    "subscription_status": .string(session.subscriptionStatus),
                    "entitlements": .array(session.entitlements.map(JSONValue.string)),
                ]),
                "products": encode(config.products),
                "assignments": encode(assignments),
                "tracked_events": encode(session.trackedEvents),
                "delegate_events": encode(session.delegateEvents),
                "logs": encode(session.logs),
            ])
        case "runtime_preview_variant":
            let sessionId = try require(arguments, "id")
            let experimentId = try require(arguments, "experiment_id")
            let variantId = try require(arguments, "variant_id")
            var session: RuntimeSessionRecord?
            try store.mutate { state in
                let index = try requireRuntimeSessionIndex(id: sessionId, state: state)
                state.runtimeSessions[index].previewVariants[experimentId] = variantId
                appendLog(to: &state.runtimeSessions[index], level: state.runtimeSessions[index].options.logLevel, message: "Previewing variant \(variantId) for experiment \(experimentId)")
                session = state.runtimeSessions[index]
            }
            return encode(session!)
        case "runtime_clear_preview":
            let sessionId = try require(arguments, "id")
            let experimentId = try require(arguments, "experiment_id")
            var session: RuntimeSessionRecord?
            try store.mutate { state in
                let index = try requireRuntimeSessionIndex(id: sessionId, state: state)
                state.runtimeSessions[index].previewVariants.removeValue(forKey: experimentId)
                appendLog(to: &state.runtimeSessions[index], level: state.runtimeSessions[index].options.logLevel, message: "Cleared preview for experiment \(experimentId)")
                session = state.runtimeSessions[index]
            }
            return encode(session!)
        case "runtime_register_view":
            let sessionId = try require(arguments, "id")
            let viewName = try require(arguments, "name")
            let metadata = arguments["metadata"]?.objectValue ?? [:]
            var session: RuntimeSessionRecord?
            try store.mutate { state in
                let index = try requireRuntimeSessionIndex(id: sessionId, state: state)
                state.runtimeSessions[index].registeredViews[viewName] = metadata
                appendLog(to: &state.runtimeSessions[index], level: state.runtimeSessions[index].options.logLevel, message: "Registered custom view '\(viewName)'")
                session = state.runtimeSessions[index]
            }
            return encode(session!)
        case "runtime_is_view_registered":
            let sessionId = try require(arguments, "id")
            let viewName = try require(arguments, "name")
            let session = try requireRuntimeSession(id: sessionId)
            return .object([
                "registered": .bool(session.registeredViews[viewName] != nil),
                "metadata": session.registeredViews[viewName].map(JSONValue.object) ?? .null,
            ])
        case "record_event":
            let projectId = try require(arguments, "project_id")
            let event = EventRecord(
                id: UUID().uuidString,
                projectId: projectId,
                channel: arguments["channel"]?.stringValue ?? "sdk",
                eventType: try require(arguments, "event_type"),
                payload: arguments["payload"]?.objectValue ?? [:],
                createdAt: Date()
            )
            try store.mutate { state in
                state.events.append(event)
                for endpoint in state.webhooks where endpoint.projectId == projectId && !endpoint.disabled {
                    let attempt = DeliveryAttemptRecord(
                        id: UUID().uuidString,
                        eventId: event.id,
                        endpointId: endpoint.id,
                        projectId: projectId,
                        status: 200,
                        statusCodeClass: 2,
                        attemptedAt: Date()
                    )
                    state.deliveryAttempts.append(attempt)
                }
            }
            return encode(event)
        case "list_events":
            let projectId = try require(arguments, "project_id")
            var events = store.snapshot().events.filter { $0.projectId == projectId }
            if let channel = arguments["channel"]?.stringValue {
                events = events.filter { $0.channel == channel }
            }
            if let eventTypes = arguments["event_types"]?.arrayValue?.compactMap({ $0.stringValue }), !eventTypes.isEmpty {
                events = events.filter { eventTypes.contains($0.eventType) }
            }
            return encode(events)
        case "get_event":
            let id = try require(arguments, "event_id")
            guard let event = store.snapshot().events.first(where: { $0.id == id }) else {
                throw MCPError.notFound("Event '\(id)' not found")
            }
            return encode(event)
        case "list_event_attempts":
            let eventId = try require(arguments, "event_id")
            var attempts = store.snapshot().deliveryAttempts.filter { $0.eventId == eventId }
            if let status = arguments["status"]?.intValue {
                attempts = attempts.filter { $0.status == status }
            }
            if let statusCodeClass = arguments["status_code_class"]?.intValue {
                attempts = attempts.filter { $0.statusCodeClass == statusCodeClass }
            }
            return encode(attempts)
        case "retry_event":
            let projectId = try require(arguments, "project_id")
            let eventId = try require(arguments, "event_id")
            let endpointId = try require(arguments, "endpoint_id")
            let attempt = DeliveryAttemptRecord(
                id: UUID().uuidString,
                eventId: eventId,
                endpointId: endpointId,
                projectId: projectId,
                status: 200,
                statusCodeClass: 2,
                attemptedAt: Date()
            )
            try store.mutate { $0.deliveryAttempts.append(attempt) }
            return encode(attempt)
        case "create_webhook_endpoint":
            let endpoint = WebhookEndpointRecord(
                id: UUID().uuidString,
                projectId: try require(arguments, "project_id"),
                url: try require(arguments, "url"),
                description: arguments["description"]?.stringValue,
                filterTypes: arguments["filter_types"]?.arrayValue?.compactMap { $0.stringValue } ?? [],
                headers: arguments["headers"]?.objectValue ?? [:],
                metadata: arguments["metadata"]?.objectValue ?? [:],
                disabled: false,
                secret: UUID().uuidString.replacingOccurrences(of: "-", with: ""),
                createdAt: Date()
            )
            try store.mutate { $0.webhooks.append(endpoint) }
            return encode(endpoint)
        case "list_webhook_endpoints":
            let projectId = try require(arguments, "project_id")
            return encode(store.snapshot().webhooks.filter { $0.projectId == projectId })
        case "get_webhook_endpoint":
            let endpointId = try require(arguments, "endpoint_id")
            guard let endpoint = store.snapshot().webhooks.first(where: { $0.id == endpointId }) else {
                throw MCPError.notFound("Webhook endpoint '\(endpointId)' not found")
            }
            return encode(endpoint)
        case "update_webhook_endpoint":
            let endpointId = try require(arguments, "endpoint_id")
            var updated: WebhookEndpointRecord?
            try store.mutate { state in
                guard let index = state.webhooks.firstIndex(where: { $0.id == endpointId }) else {
                    throw MCPError.notFound("Webhook endpoint '\(endpointId)' not found")
                }
                if let url = arguments["url"]?.stringValue { state.webhooks[index].url = url }
                if arguments.keys.contains("description") { state.webhooks[index].description = arguments["description"]?.stringValue }
                if let filterTypes = arguments["filter_types"]?.arrayValue?.compactMap({ $0.stringValue }) { state.webhooks[index].filterTypes = filterTypes }
                if let headers = arguments["headers"]?.objectValue { state.webhooks[index].headers = headers }
                if let metadata = arguments["metadata"]?.objectValue { state.webhooks[index].metadata = metadata }
                if let disabled = arguments["disabled"]?.boolValue { state.webhooks[index].disabled = disabled }
                updated = state.webhooks[index]
            }
            return encode(updated!)
        case "delete_webhook_endpoint":
            let endpointId = try require(arguments, "endpoint_id")
            try store.mutate { $0.webhooks.removeAll { $0.id == endpointId } }
            return .object(["deleted": .bool(true)])
        case "rotate_webhook_secret":
            let endpointId = try require(arguments, "endpoint_id")
            var updated: WebhookEndpointRecord?
            try store.mutate { state in
                guard let index = state.webhooks.firstIndex(where: { $0.id == endpointId }) else {
                    throw MCPError.notFound("Webhook endpoint '\(endpointId)' not found")
                }
                state.webhooks[index].secret = UUID().uuidString.replacingOccurrences(of: "-", with: "")
                updated = state.webhooks[index]
            }
            return encode(updated!)
        default:
            throw MCPError.notFound("Unknown tool '\(name)'")
        }
    }

    private func requireProject(id: String) throws -> ProjectRecord {
        guard let project = store.snapshot().projects.first(where: { $0.id == id }) else {
            throw MCPError.notFound("Project '\(id)' not found")
        }
        return project
    }

    private func requireApplication(id: String) throws -> ApplicationRecord {
        guard let app = store.snapshot().applications.first(where: { $0.id == id }) else {
            throw MCPError.notFound("Application '\(id)' not found")
        }
        return app
    }

    private func requireRuntimeSession(id: String) throws -> RuntimeSessionRecord {
        guard let session = store.snapshot().runtimeSessions.first(where: { $0.id == id }) else {
            throw MCPError.notFound("Runtime session '\(id)' not found")
        }
        return session
    }

    private func requireRuntimeSessionIndex(id: String, state: MCPState) throws -> Int {
        guard let index = state.runtimeSessions.firstIndex(where: { $0.id == id }) else {
            throw MCPError.notFound("Runtime session '\(id)' not found")
        }
        return index
    }

    private func presentRuntimePaywall(
        state: inout MCPState,
        sessionIndex: Int,
        paywallId: String,
        campaignId: String?,
        experimentId: String?,
        variantId: String?
    ) throws {
        guard let paywall = state.paywalls.first(where: {
            $0.applicationId == state.runtimeSessions[sessionIndex].applicationId && $0.id == paywallId && !$0.archived
        }) else {
            throw MCPError.notFound("Paywall '\(paywallId)' not found")
        }
        state.runtimeSessions[sessionIndex].currentPaywallId = paywallId
        state.runtimeSessions[sessionIndex].currentCampaignId = campaignId
        state.runtimeSessions[sessionIndex].currentExperimentId = experimentId
        state.runtimeSessions[sessionIndex].currentVariantId = variantId
        appendDelegateEvent(
            to: &state.runtimeSessions[sessionIndex],
            name: "didPresentPaywall",
            payload: [
                "paywallId": .string(paywallId),
                "paywallName": .string(paywall.name),
                "campaignId": campaignId.map(JSONValue.string) ?? .null,
                "experimentId": experimentId.map(JSONValue.string) ?? .null,
                "variantId": variantId.map(JSONValue.string) ?? .null,
            ]
        )
        state.runtimeSessions[sessionIndex].trackedEvents.append(RuntimeTrackedEventRecord(
            name: "paywall_open",
            properties: [
                "paywall_id": .string(paywallId),
                "campaign_id": campaignId.map(JSONValue.string) ?? .null,
                "experiment_id": experimentId.map(JSONValue.string) ?? .null,
                "variant_id": variantId.map(JSONValue.string) ?? .null,
            ],
            createdAt: Date()
        ))
        appendLog(to: &state.runtimeSessions[sessionIndex], level: state.runtimeSessions[sessionIndex].options.logLevel, message: "Presented paywall \(paywallId)")
    }

    private func validatePaywallSchema(paywallSchema: PaywallSchema, applicationId: String?, state: MCPState? = nil) throws {
        let sourceState = state ?? store.snapshot()
        if let applicationId {
            guard let app = sourceState.applications.first(where: { $0.id == applicationId }) else {
                throw MCPError.notFound("Application '\(applicationId)' not found")
            }
            let projectProducts = Set(sourceState.products.filter { $0.projectId == app.projectId }.map(\.id))
            let missing = paywallSchema.products?
                .compactMap(\.productId)
                .filter { !projectProducts.contains($0) } ?? []
            if !missing.isEmpty {
                throw MCPError.invalidParams("Paywall references unknown product ids: \(missing)")
            }
        }
    }

    private func validateCampaign(campaign: Campaign, applicationId: String, state: MCPState? = nil) throws {
        let sourceState = state ?? store.snapshot()
        let paywallIds = Set(sourceState.paywalls.filter { $0.applicationId == applicationId && !$0.archived }.map(\.id))
        for audience in campaign.audiences {
            if let experiment = audience.experiment {
                let totalTraffic = experiment.variants.map(\.trafficPercentage).reduce(0, +)
                if totalTraffic + experiment.holdoutPercentage > 100 {
                    throw MCPError.invalidParams("Experiment '\(experiment.id)' traffic exceeds 100%")
                }
                for variant in experiment.variants where !paywallIds.contains(variant.paywallId) {
                    throw MCPError.invalidParams("Campaign variant references unknown paywall id '\(variant.paywallId)'")
                }
            }
        }
    }
}

private func appendLog(to session: inout RuntimeSessionRecord, level: String, message: String) {
    session.logs.append(RuntimeLogRecord(level: level, message: message, createdAt: Date()))
    if session.logs.count > 100 {
        session.logs.removeFirst(session.logs.count - 100)
    }
}

private func appendDelegateEvent(to session: inout RuntimeSessionRecord, name: String, payload: [String: JSONValue]) {
    session.delegateEvents.append(RuntimeDelegateEventRecord(name: name, payload: payload, createdAt: Date()))
    if session.delegateEvents.count > 100 {
        session.delegateEvents.removeFirst(session.delegateEvents.count - 100)
    }
}

private func resolveBaseURL(options: RuntimeOptionsRecord) -> String {
    switch options.networkEnvironment {
    case "production":
        return "https://api.agentwallie.com"
    case "staging":
        return "https://staging-api.agentwallie.com"
    case "custom":
        return options.customBaseURL ?? ""
    default:
        return options.customBaseURL ?? options.networkEnvironment
    }
}

private func slugify(_ value: String) -> String {
    value.lowercased()
        .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
        .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
}

private func require(_ arguments: [String: JSONValue], _ key: String) throws -> String {
    guard let value = arguments[key]?.stringValue, !value.isEmpty else {
        throw MCPError.invalidParams("Missing required string parameter '\(key)'")
    }
    return value
}

private func requireValue(_ arguments: [String: JSONValue], _ key: String) throws -> JSONValue {
    guard let value = arguments[key] else {
        throw MCPError.invalidParams("Missing required parameter '\(key)'")
    }
    return value
}

private func decode<T: Decodable>(_ type: T.Type, from value: JSONValue) throws -> T {
    let any = value.toAny()
    let data = try JSONSerialization.data(withJSONObject: any)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(T.self, from: data)
}

private func decodeEnum<T: RawRepresentable>(_ type: T.Type, value: JSONValue) throws -> T where T.RawValue == String {
    guard let raw = value.stringValue, let result = T(rawValue: raw) else {
        throw MCPError.invalidParams("Invalid value for enum \(T.self)")
    }
    return result
}

private func encode<T: Encodable>(_ value: T) -> JSONValue {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try! encoder.encode(value)
    let object = try! JSONSerialization.jsonObject(with: data)
    return JSONValue.fromAny(object)
}
