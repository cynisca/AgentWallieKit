import AgentWallieKit
import AgentWallieMCPCore
import Foundation

struct HarnessFailure: Error, CustomStringConvertible {
    let description: String
}

var invokedTools = Set<String>()

@discardableResult
func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws -> Bool {
    if !condition() {
        throw HarnessFailure(description: message)
    }
    return true
}

func expectThrows(_ message: String, _ work: () throws -> Void) throws {
    do {
        try work()
        throw HarnessFailure(description: message)
    } catch is HarnessFailure {
        throw HarnessFailure(description: message)
    } catch {
    }
}

func requireObject(_ value: JSONValue, _ message: String) throws -> [String: JSONValue] {
    guard let object = value.objectValue else {
        throw HarnessFailure(description: message)
    }
    return object
}

func requireArray(_ value: JSONValue, _ message: String) throws -> [JSONValue] {
    guard let array = value.arrayValue else {
        throw HarnessFailure(description: message)
    }
    return array
}

func call(_ service: AgentWallieMCPService, _ name: String, _ arguments: [String: JSONValue] = [:]) throws -> JSONValue {
    invokedTools.insert(name)
    return try service.callTool(name: name, arguments: arguments)
}

func textComponentSchema(productId: String) -> PaywallSchema {
    PaywallSchema(
        version: "1",
        name: "Premium",
        settings: PaywallSettings(presentation: .modal),
        theme: PaywallTheme(),
        products: [ProductSlot(slot: "primary", label: "Yearly", productId: productId)],
        components: [
            .text(TextComponentData(id: "title", props: .init(content: "Go Premium", textStyle: "title1", alignment: "center"))),
            .ctaButton(CTAButtonComponentData(id: "buy", props: .init(text: "Buy", action: .purchase, product: "primary"))),
        ]
    )
}

func campaignDocument(paywallId: String) -> Campaign {
    Campaign(
        id: "campaign-main",
        name: "Main Campaign",
        status: .active,
        placements: [
            Placement(id: "placement-main", name: "feature_gate", type: .standard, status: .active),
        ],
        audiences: [
            Audience(
                id: "audience-main",
                name: "US users",
                priorityOrder: 1,
                filters: [
                    AudienceFilter(field: "user.country", operator: .is, value: .string("US"), conjunction: nil),
                ],
                entitlementCheck: nil,
                frequencyCap: nil,
                experiment: Experiment(
                    id: "experiment-main",
                    variants: [
                        ExperimentVariant(id: "variant-a", paywallId: paywallId, trafficPercentage: 100),
                    ],
                    holdoutPercentage: 0,
                    status: .running
                )
            ),
        ]
    )
}

func runCoreFlowTests(service: AgentWallieMCPService) throws {
    let whoami = try requireObject(call(service, "whoami"), "whoami")
    try expect(whoami["server"]?.stringValue == "AgentWallieMCPServer", "whoami should return server metadata")

    let org = try requireObject(call(service, "create_organization", ["name": .string("Cynisca")]), "organization object")
    let orgId = org["id"]!.stringValue!
    let organizations = try requireArray(call(service, "list_organizations"), "organizations")
    try expect(organizations.count == 1, "list_organizations should return organization")

    let project = try requireObject(call(service, "create_project", [
        "organization_id": .string(orgId),
        "name": .string("Prayer App"),
        "metadata": .object(["tier": .string("prod")]),
    ]), "project object")
    let projectId = project["id"]!.stringValue!
    let projects = try requireArray(call(service, "list_projects", ["organization_id": .string(orgId)]), "project list")
    try expect(projects.count == 1, "project listing should include created project")
    let fetchedProject = try requireObject(call(service, "get_project", ["id": .string(projectId)]), "fetched project")
    try expect(fetchedProject["name"]?.stringValue == "Prayer App", "get_project should return project")
    let updatedProject = try requireObject(call(service, "update_project", ["id": .string(projectId), "name": .string("Prayer App Updated")]), "updated project")
    try expect(updatedProject["name"]?.stringValue == "Prayer App Updated", "update_project should update name")
    _ = try call(service, "archive_project", ["id": .string(projectId)])
    let archivedProjects = try requireArray(call(service, "list_projects", ["organization_id": .string(orgId), "archived": .bool(true)]), "archived project list")
    try expect(archivedProjects.count == 1, "archived projects should be listed")
    _ = try call(service, "unarchive_project", ["id": .string(projectId)])

    let app = try requireObject(call(service, "create_application", [
        "project_id": .string(projectId),
        "name": .string("iOS App"),
        "platform": .string("ios"),
        "bundle_id": .string("com.example.app"),
    ]), "application object")
    let appId = app["id"]!.stringValue!
    let originalApiKey = app["apiKey"]!.stringValue!
    let apps = try requireArray(call(service, "list_applications", ["project_id": .string(projectId)]), "application list")
    try expect(apps.count == 1, "list_applications should return one app")
    let fetchedApp = try requireObject(call(service, "get_application", ["id": .string(appId)]), "get application")
    try expect(fetchedApp["bundleId"]?.stringValue == "com.example.app", "get_application should expose bundle id")
    let updatedApp = try requireObject(call(service, "update_application", ["id": .string(appId), "name": .string("Updated iOS App")]), "updated application")
    try expect(updatedApp["name"]?.stringValue == "Updated iOS App", "update_application should update name")
    _ = try call(service, "archive_application", ["id": .string(appId)])
    _ = try call(service, "unarchive_application", ["id": .string(appId)])

    let rotatedApp = try requireObject(call(service, "rotate_application_api_key", ["id": .string(appId)]), "rotated application")
    try expect(rotatedApp["apiKey"]!.stringValue! != originalApiKey, "api key should rotate")

    let entitlement = try requireObject(call(service, "create_entitlement", [
        "project_id": .string(projectId),
        "identifier": .string("premium"),
        "name": .string("Premium"),
    ]), "entitlement")
    let entitlementId = entitlement["id"]!.stringValue!
    let entitlements = try requireArray(call(service, "list_entitlements", ["project_id": .string(projectId)]), "entitlements list")
    try expect(entitlements.count == 1, "list_entitlements should return entitlement")
    let fetchedEntitlement = try requireObject(call(service, "get_entitlement", ["id": .string(entitlementId)]), "fetched entitlement")
    try expect(fetchedEntitlement["identifier"]?.stringValue == "premium", "get_entitlement should return identifier")

    let product = try requireObject(call(service, "create_product", [
        "project_id": .string(projectId),
        "identifier": .string("premium.yearly"),
        "name": .string("Yearly"),
        "entitlements": .array([.string(entitlementId)]),
        "price": .object(["amount": .number(4999), "currency": .string("USD")]),
        "subscription": .object(["period": .string("year"), "periodCount": .number(1), "trialPeriodDays": .number(7)]),
    ]), "product")
    let productId = product["id"]!.stringValue!
    let products = try requireArray(call(service, "list_products", ["project_id": .string(projectId)]), "products list")
    try expect(products.count == 1, "list_products should return one product")
    let fetchedProduct = try requireObject(call(service, "get_product", ["id": .string(productId)]), "fetched product")
    try expect(fetchedProduct["identifier"]?.stringValue == "premium.yearly", "get_product should return identifier")
    let updatedProduct = try requireObject(call(service, "update_product", [
        "id": .string(productId),
        "name": .string("Yearly Updated"),
        "metadata": .object(["badge": .string("best")]),
    ]), "updated product")
    try expect(updatedProduct["name"]?.stringValue == "Yearly Updated", "update_product should update name")

    _ = try call(service, "update_entitlement", [
        "id": .string(entitlementId),
        "products": .array([.string(productId)]),
    ])
    let updatedEntitlement = try requireObject(call(service, "update_entitlement", [
        "id": .string(entitlementId),
        "description": .string("Premium access"),
        "products": .array([.string(productId)]),
    ]), "updated entitlement")
    try expect(updatedEntitlement["description"]?.stringValue == "Premium access", "update_entitlement should update description")

    let templates = try requireArray(call(service, "list_templates"), "templates")
    try expect(templates.count >= 2, "list_templates should return built-ins")
    let template = try requireObject(call(service, "get_template", ["id": .string("blank")]), "template")
    try expect(template["name"]?.stringValue == "Blank", "get_template should return template")

    let schemaValue = try encodeValue(textComponentSchema(productId: productId))
    _ = try call(service, "validate_paywall", [
        "application_id": .string(appId),
        "schema": schemaValue,
    ])

    let paywall = try requireObject(call(service, "create_paywall", [
        "application_id": .string(appId),
        "name": .string("Premium Wall"),
        "identifier": .string("premium-wall"),
        "products": .array([.string(productId)]),
        "schema": schemaValue,
    ]), "paywall")
    let paywallId = paywall["id"]!.stringValue!
    let paywalls = try requireArray(call(service, "list_paywalls", ["application_id": .string(appId)]), "paywalls list")
    try expect(paywalls.count == 1, "list_paywalls should return paywall")
    let fetchedPaywall = try requireObject(call(service, "get_paywall", ["id": .string(paywallId)]), "fetched paywall")
    try expect(fetchedPaywall["identifier"]?.stringValue == "premium-wall", "get_paywall should return identifier")

    let updatedSchema = try encodeValue(
        PaywallSchema(
            version: "2",
            name: "Premium v2",
            settings: PaywallSettings(presentation: .fullscreen),
            theme: PaywallTheme(),
            products: [ProductSlot(slot: "primary", label: "Yearly", productId: productId)],
            components: [
                .text(TextComponentData(id: "headline", props: .init(content: "Premium v2", textStyle: "title1", alignment: "center"))),
            ]
        )
    )
    let updatedPaywall = try requireObject(call(service, "update_paywall", [
        "id": .string(paywallId),
        "schema": updatedSchema,
        "publish": .bool(true),
        "notes": .string("Second version"),
    ]), "updated paywall")
    let versions = try requireArray(updatedPaywall["versions"]!, "versions")
    try expect(versions.count == 2, "paywall should track versions")
    let latestVersion = try requireObject(versions.last!, "latest version")
    _ = try call(service, "publish_paywall", [
        "id": .string(paywallId),
        "version_id": latestVersion["id"]!,
    ])
    _ = try call(service, "archive_paywall", ["id": .string(paywallId)])
    _ = try call(service, "unarchive_paywall", ["id": .string(paywallId)])

    try expectThrows("validate_paywall should reject unknown product ids") {
        _ = try call(service, "validate_paywall", [
            "application_id": .string(appId),
            "schema": try encodeValue(textComponentSchema(productId: "missing-product")),
        ])
    }

    let campaign = try requireObject(call(service, "create_campaign", [
        "application_id": .string(appId),
        "campaign": try encodeValue(campaignDocument(paywallId: paywallId)),
        "description": .string("Main campaign"),
    ]), "campaign")
    let campaignId = campaign["id"]!.stringValue!
    let fetchedCampaign = try requireObject(call(service, "get_campaign", ["id": .string(campaignId)]), "fetched campaign")
    try expect(fetchedCampaign["description"]?.stringValue == "Main campaign", "get_campaign should return campaign")
    let updatedCampaign = try requireObject(call(service, "update_campaign", [
        "id": .string(campaignId),
        "notes": .string("Updated notes"),
        "campaign": try encodeValue(campaignDocument(paywallId: paywallId)),
    ]), "updated campaign")
    try expect(updatedCampaign["notes"]?.stringValue == "Updated notes", "update_campaign should update notes")
    _ = try call(service, "archive_campaign", ["id": .string(campaignId)])
    _ = try call(service, "unarchive_campaign", ["id": .string(campaignId)])
    _ = try call(service, "update_campaign", [
        "id": .string(campaignId),
        "campaign": try encodeValue(campaignDocument(paywallId: paywallId)),
    ])

    let compiledConfig = try requireObject(call(service, "get_compiled_config", [
        "application_id": .string(appId),
    ]), "compiled config")
    let compiledPaywalls = try requireObject(compiledConfig["paywalls"]!, "paywalls")
    try expect(compiledPaywalls.keys.contains(paywallId), "compiled config should contain paywall")

    let runtimeSession = try requireObject(call(service, "create_runtime_session", [
        "application_id": .string(appId),
        "options": .object([
            "defaultPresentation": .string("sheet"),
            "networkEnvironment": .string("staging"),
            "logLevel": .string("debug"),
            "collectDeviceAttributes": .bool(true),
            "enableShakeDebugger": .bool(true),
        ]),
    ]), "runtime session")
    let runtimeId = runtimeSession["id"]!.stringValue!
    let runtimeSessions = try requireArray(call(service, "list_runtime_sessions", ["application_id": .string(appId)]), "runtime session list")
    try expect(runtimeSessions.count == 1, "list_runtime_sessions should return one session")
    let runtimeWait = try requireObject(call(service, "runtime_wait_for_config", ["id": .string(runtimeId), "include_config": .bool(true)]), "runtime wait")
    try expect(runtimeWait["ready"]?.boolValue == true, "runtime_wait_for_config should return ready")
    _ = try call(service, "runtime_identify", ["id": .string(runtimeId), "user_id": .string("user-1")])
    let runtimeState = try requireObject(call(service, "get_runtime_session", ["id": .string(runtimeId)]), "runtime state")
    try expect(runtimeState["userId"]?.stringValue == "user-1", "runtime_identify should set user id")
    _ = try call(service, "runtime_set_subscription_state", [
        "id": .string(runtimeId),
        "status": .string("active"),
        "entitlements": .array([.string("premium")]),
    ])
    _ = try call(service, "runtime_set_user_attributes", [
        "id": .string(runtimeId),
        "attributes": .object(["country": .string("US"), "plan": .string("trial")]),
    ])
    _ = try call(service, "runtime_track_event", [
        "id": .string(runtimeId),
        "name": .string("app_launch"),
        "properties": .object(["source": .string("test")]),
    ])
    let runtimePaywall = try requireObject(call(service, "runtime_get_paywall_for_placement", [
        "id": .string(runtimeId),
        "placement": .string("feature_gate"),
    ]), "runtime paywall for placement")
    try expect(runtimePaywall["paywall_id"]?.stringValue == paywallId, "runtime_get_paywall_for_placement should resolve paywall")
    _ = try call(service, "runtime_preview_variant", [
        "id": .string(runtimeId),
        "experiment_id": .string("experiment-main"),
        "variant_id": .string("variant-a"),
    ])
    let runtimePlacement = try requireObject(call(service, "runtime_register_placement", [
        "id": .string(runtimeId),
        "placement": .string("feature_gate"),
    ]), "runtime placement")
    try expect(runtimePlacement["presented"]?.boolValue == true, "runtime_register_placement should present matched paywall")
    _ = try call(service, "runtime_present_paywall", ["id": .string(runtimeId), "paywall_id": .string(paywallId)])
    _ = try call(service, "runtime_handle_deep_link", ["id": .string(runtimeId), "url": .string("agentwallie://paywall/\(paywallId)")])
    _ = try call(service, "runtime_register_view", [
        "id": .string(runtimeId),
        "name": .string("HeroBanner"),
        "metadata": .object(["kind": .string("stub")]),
    ])
    let viewCheck = try requireObject(call(service, "runtime_is_view_registered", ["id": .string(runtimeId), "name": .string("HeroBanner")]), "view check")
    try expect(viewCheck["registered"]?.boolValue == true, "runtime_is_view_registered should confirm view")
    let debugger = try requireObject(call(service, "runtime_show_debugger", ["id": .string(runtimeId)]), "debugger")
    try expect(debugger["status"] != nil, "runtime_show_debugger should return status")
    _ = try call(service, "runtime_clear_preview", ["id": .string(runtimeId), "experiment_id": .string("experiment-main")])
    _ = try call(service, "runtime_reset", ["id": .string(runtimeId)])

    let preview = try requireObject(call(service, "preview_placement", [
        "application_id": .string(appId),
        "placement": .string("feature_gate"),
        "user_id": .string("user-1"),
        "user_attributes": .object(["country": .string("US")]),
        "include_config": .bool(true),
    ]), "preview")
    try expect(preview["matched"]?.boolValue == true, "placement should match")
    try expect(preview["paywallId"]?.stringValue == paywallId, "preview should select paywall")

    let assignment = try requireObject(call(service, "get_assignment", [
        "application_id": .string(appId),
        "user_id": .string("user-1"),
        "experiment_id": .string("experiment-main"),
    ]), "assignment")
    try expect(assignment["experimentId"]?.stringValue == "experiment-main", "assignment should persist")

    _ = try call(service, "reset_assignments", [
        "application_id": .string(appId),
        "user_id": .string("user-1"),
    ])

    let endpoint = try requireObject(call(service, "create_webhook_endpoint", [
        "project_id": .string(projectId),
        "url": .string("https://example.com/hook"),
        "filter_types": .array([.string("paywall_open")]),
    ]), "endpoint")
    let endpointId = endpoint["id"]!.stringValue!

    let event = try requireObject(call(service, "record_event", [
        "project_id": .string(projectId),
        "event_type": .string("paywall_open"),
        "payload": .object(["campaign_id": .string(campaignId)]),
    ]), "event")
    let eventId = event["id"]!.stringValue!

    let attempts = try requireArray(call(service, "list_event_attempts", [
        "event_id": .string(eventId),
    ]), "attempts")
    try expect(!attempts.isEmpty, "event should create delivery attempts")

    let retried = try requireObject(call(service, "retry_event", [
        "project_id": .string(projectId),
        "event_id": .string(eventId),
        "endpoint_id": .string(endpointId),
    ]), "retry")
    try expect(retried["endpointId"]?.stringValue == endpointId, "retry should target endpoint")

    let rotatedEndpoint = try requireObject(call(service, "rotate_webhook_secret", [
        "endpoint_id": .string(endpointId),
    ]), "rotated endpoint")
    try expect(rotatedEndpoint["secret"]?.stringValue != endpoint["secret"]?.stringValue, "webhook secret should rotate")

    let campaigns = try requireArray(call(service, "list_campaigns", [
        "application_id": .string(appId),
    ]), "campaign list")
    try expect(campaigns.count == 1, "campaign listing should return one record")

    let events = try requireArray(call(service, "list_events", ["project_id": .string(projectId)]), "events list")
    try expect(events.count == 1, "list_events should return recorded event")
    let fetchedEvent = try requireObject(call(service, "get_event", ["event_id": .string(eventId)]), "fetched event")
    try expect(fetchedEvent["eventType"]?.stringValue == "paywall_open", "get_event should return event")
    let endpoints = try requireArray(call(service, "list_webhook_endpoints", ["project_id": .string(projectId)]), "endpoint list")
    try expect(endpoints.count == 1, "list_webhook_endpoints should return endpoint")
    let fetchedEndpoint = try requireObject(call(service, "get_webhook_endpoint", ["endpoint_id": .string(endpointId)]), "fetched endpoint")
    try expect(fetchedEndpoint["url"]?.stringValue == "https://example.com/hook", "get_webhook_endpoint should return endpoint")
    let updatedEndpoint = try requireObject(call(service, "update_webhook_endpoint", [
        "endpoint_id": .string(endpointId),
        "disabled": .bool(true),
    ]), "updated endpoint")
    try expect(updatedEndpoint["disabled"]?.boolValue == true, "update_webhook_endpoint should update endpoint")

    let deleteProduct = try requireObject(call(service, "create_product", [
        "project_id": .string(projectId),
        "identifier": .string("premium.monthly"),
    ]), "delete product")
    _ = try call(service, "delete_product", ["id": deleteProduct["id"]!])
    let deleteEntitlement = try requireObject(call(service, "create_entitlement", [
        "project_id": .string(projectId),
        "identifier": .string("temporary"),
    ]), "delete entitlement")
    _ = try call(service, "delete_entitlement", ["id": deleteEntitlement["id"]!])
    _ = try call(service, "delete_webhook_endpoint", ["endpoint_id": .string(endpointId)])

    try expectThrows("runtime_handle_deep_link should reject invalid urls") {
        _ = try call(service, "runtime_handle_deep_link", ["id": .string(runtimeId), "url": .string("https://example.com")])
    }
    try expectThrows("create_campaign should reject invalid traffic totals") {
        let badCampaign = Campaign(
            id: "bad-campaign",
            name: "Bad",
            status: .active,
            placements: [Placement(id: "p", name: "feature_gate", type: .standard, status: .active)],
            audiences: [
                Audience(
                    id: "a",
                    name: "All",
                    priorityOrder: 1,
                    filters: [],
                    experiment: Experiment(
                        id: "e",
                        variants: [ExperimentVariant(id: "v", paywallId: paywallId, trafficPercentage: 80)],
                        holdoutPercentage: 30,
                        status: .running
                    )
                ),
            ]
        )
        _ = try call(service, "create_campaign", [
            "application_id": .string(appId),
            "campaign": try encodeValue(badCampaign),
        ])
    }
}

func runJSONRPCTests(service: AgentWallieMCPService) throws {
    let server = MCPServerEngine(service: service)

    func send(_ id: Int, _ method: String, _ params: JSONValue? = nil) throws -> [String: JSONValue] {
        let request = JSONRPCRequest(jsonrpc: "2.0", id: .number(Double(id)), method: method, params: params)
        let data = try JSONEncoder().encode(request)
        let line = String(data: data, encoding: .utf8)!
        guard let responseLine = server.handle(line: line) else {
            throw HarnessFailure(description: "missing response for \(method)")
        }
        let response = try JSONDecoder().decode(JSONRPCResponse.self, from: Data(responseLine.utf8))
        if let error = response.error {
            throw HarnessFailure(description: "rpc error \(error.code): \(error.message)")
        }
        return try requireObject(response.result!, "rpc result object")
    }

    let initialize = try send(1, "initialize", .object([:]))
    try expect(initialize["serverInfo"] != nil, "initialize should return serverInfo")

    let tools = try send(2, "tools/list")
    let toolArray = try requireArray(tools["tools"]!, "tool list")
    try expect(toolArray.count >= 40, "tool list should expose broad surface")

    let whoami = try send(3, "tools/call", .object([
        "name": .string("whoami"),
        "arguments": .object([:]),
    ]))
    let structured = try requireObject(whoami["structuredContent"]!, "structured content")
    try expect(structured["server"]?.stringValue == "AgentWallieMCPServer", "tools/call should execute tool")
}

func encodeValue<T: Encodable>(_ value: T) throws -> JSONValue {
    let encoder = JSONEncoder()
    let data = try encoder.encode(value)
    let object = try JSONSerialization.jsonObject(with: data)
    return JSONValue.fromAny(object)
}

let stateURL = URL(fileURLWithPath: "/tmp/agentwallie-mcp-harness-\(UUID().uuidString).json")

do {
    let store = try AgentWallieMCPStore(fileURL: stateURL)
    let service = AgentWallieMCPService(store: store)
    try runCoreFlowTests(service: service)
    try runJSONRPCTests(service: service)
    let definedTools = Set(service.toolDefinitions().map(\.name))
    let missingCoverage = definedTools.subtracting(invokedTools)
    try expect(missingCoverage.isEmpty, "missing direct harness coverage for tools: \(missingCoverage.sorted())")
    print("AgentWallie MCP harness passed")
} catch {
    fputs("AgentWallie MCP harness failed: \(error)\n", stderr)
    exit(1)
}
