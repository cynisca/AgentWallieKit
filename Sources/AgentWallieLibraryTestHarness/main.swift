import AgentWallieKit
import Foundation
import SwiftUI

struct LibraryHarnessFailure: Error, CustomStringConvertible {
    let description: String
}

@discardableResult
func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws -> Bool {
    if !condition() {
        throw LibraryHarnessFailure(description: message)
    }
    return true
}

func expectThrows(_ message: String, _ work: () throws -> Void) throws {
    do {
        try work()
        throw LibraryHarnessFailure(description: message)
    } catch is LibraryHarnessFailure {
        throw LibraryHarnessFailure(description: message)
    } catch {
    }
}

func encodeDecode<T: Codable>(_ value: T, as type: T.Type = T.self) throws -> T {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let data = try encoder.encode(value)
    return try decoder.decode(type, from: data)
}

@available(iOS 16.0, macOS 13.0, *)
func runHarness() throws {
    let options = AgentWallieOptions(
        defaultPresentation: .sheet,
        networkEnvironment: .staging,
        logLevel: .debug,
        collectDeviceAttributes: false,
        enableShakeDebugger: true
    )
    try expect(options.defaultPresentation == .sheet, "AgentWallieOptions should preserve presentation")
    try expect(options.networkEnvironment.baseURL.absoluteString == "https://staging-api.agentwallie.com", "staging base URL should resolve")
    try expect(options.logLevel == .debug, "log level should preserve value")
    try expect(options.collectDeviceAttributes == false, "collectDeviceAttributes should preserve value")
    try expect(options.enableShakeDebugger == true, "enableShakeDebugger should preserve value")

    let product = AWProduct(
        id: "product_1",
        name: "Yearly",
        store: .apple,
        storeProductId: "premium.yearly",
        entitlements: ["premium"],
        basePlanId: nil,
        offerIds: nil,
        displayPrice: "$49.99",
        displayPeriod: "year"
    )
    let decodedProduct = try encodeDecode(product, as: AWProduct.self)
    try expect(decodedProduct.storeProductId == "premium.yearly", "AWProduct should round-trip codably")

    let paywall = PaywallSchema(
        version: "1",
        name: "Premium",
        settings: PaywallSettings(
            presentation: .modal,
            closeButton: true,
            closeButtonDelayMs: 250,
            backgroundColor: "#FFFFFF",
            scrollEnabled: true,
            safeAreaInsets: false,
            backgroundGradient: BackgroundGradient(colors: ["#111111", "#222222"], direction: "vertical"),
            closeButtonStyle: "text"
        ),
        theme: PaywallTheme(
            background: "#FFFFFF",
            primary: "#111111",
            secondary: "#222222",
            textPrimary: "#333333",
            textSecondary: "#444444",
            accent: "#555555",
            surface: "#666666",
            cornerRadius: 14,
            fontFamily: "system",
            fontFamilies: FontFamilies(display: "A", heading: "B", body: "C", mono: "D")
        ),
        products: [
            ProductSlot(slot: "primary", label: "Yearly", productId: "product_1"),
            ProductSlot(slot: "secondary", label: "Monthly", productId: "product_2"),
        ],
        components: [
            .text(TextComponentData(id: "headline", props: .init(content: "Upgrade", textStyle: "title1", alignment: "center"))),
            .ctaButton(CTAButtonComponentData(id: "cta", props: .init(text: "Buy", action: .purchase, product: "primary"))),
        ]
    )
    let decodedPaywall = try encodeDecode(paywall, as: PaywallSchema.self)
    try expect(decodedPaywall.components.count == 2, "PaywallSchema should round-trip components")
    try expect(decodedPaywall.settings.closeButtonDelayMs == 250, "Paywall settings should round-trip")

    let campaign = Campaign(
        id: "campaign_1",
        name: "Main",
        status: .active,
        placements: [Placement(id: "placement_1", name: "feature_gate", type: .standard, status: .active)],
        audiences: [
            Audience(
                id: "audience_1",
                name: "US",
                priorityOrder: 1,
                filters: [
                    AudienceFilter(field: "user.country", operator: .is, value: .string("US")),
                ],
                entitlementCheck: nil,
                frequencyCap: FrequencyCap(type: .oncePerDay, limit: 1),
                experiment: Experiment(
                    id: "experiment_1",
                    variants: [ExperimentVariant(id: "variant_1", paywallId: "paywall_1", trafficPercentage: 100)],
                    holdoutPercentage: 0,
                    status: .running
                )
            ),
        ]
    )
    let decodedCampaign = try encodeDecode(campaign, as: Campaign.self)
    try expect(decodedCampaign.audiences.first?.frequencyCap?.type == .oncePerDay, "Campaign should round-trip frequency caps")

    let assignment = ExperimentAssignment.assignVariant(
        userId: "user_1",
        experimentId: "experiment_1",
        variants: [ExperimentVariant(id: "variant_1", paywallId: "paywall_1", trafficPercentage: 100)],
        holdoutPercentage: 0
    )
    try expect(assignment?.variantId == "variant_1", "ExperimentAssignment should deterministically assign variant")

    let suiteName = "agentwallie-harness-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    let store = AssignmentStore(defaults: defaults)
    let stored = StoredAssignment(variantId: "variant_1", paywallId: "paywall_1", isHoldout: false)
    store.saveAssignment(userId: "user_1", experimentId: "experiment_1", assignment: stored)
    try expect(store.getAssignment(userId: "user_1", experimentId: "experiment_1")?.variantId == "variant_1", "AssignmentStore should persist assignments")
    try expect(store.getAssignmentAge(userId: "user_1", experimentId: "experiment_1") != nil, "AssignmentStore should report assignment age")
    store.clearAssignment(userId: "user_1", experimentId: "experiment_1")
    try expect(store.getAssignment(userId: "user_1", experimentId: "experiment_1") == nil, "AssignmentStore should clear single assignments")

    let userManager = UserManager(defaults: defaults)
    userManager.identify(userId: "known-user")
    userManager.setAttributes(["country": "US", "score": 7])
    let context = userManager.buildContext(eventParams: ["source": "push"])
    let contextUser = context["user"] as? [String: Any]
    try expect(contextUser?["id"] as? String == "known-user", "UserManager should identify users")
    try expect(contextUser?["country"] as? String == "US", "UserManager should merge attributes into context")
    userManager.reset()
    try expect(userManager.userId == nil, "UserManager reset should clear user")

    let entitlementManager = EntitlementManager()
    entitlementManager.updateProductMapping(products: [product])
    try expect(entitlementManager.entitlements(for: "premium.yearly") == ["premium"], "EntitlementManager should map product entitlements")
    entitlementManager.handlePurchase(storeProductId: "premium.yearly")
    try expect(entitlementManager.subscriptionStatus == .active, "EntitlementManager should mark status active after purchase")
    try expect(entitlementManager.activeEntitlements.contains("premium"), "EntitlementManager should track purchased entitlements")
    entitlementManager.reset()
    try expect(entitlementManager.subscriptionStatus == .unknown, "EntitlementManager reset should clear status")

    let resolver = ExpressionResolver(
        products: decodedPaywall.products,
        selectedProductIndex: 0,
        theme: decodedPaywall.theme,
        userAttributes: ["country": "US"],
        resolvedProducts: [
            ResolvedProductInfo(
                slot: "primary",
                label: "Yearly",
                productId: "product_1",
                storeProductId: "premium.yearly",
                price: "$49.99",
                pricePerMonth: "$4.17",
                period: "year",
                periodLabel: "/yr",
                trialPeriod: "7 days",
                trialPrice: "Free",
                savingsPercentage: 30
            ),
        ],
        awProducts: [product]
    )
    let resolvedText = resolver.resolve("{{ products.selected.price }} {{ user.country }} {{ theme.primary }}")
    try expect(resolvedText.contains("$49.99"), "ExpressionResolver should resolve product price")
    try expect(resolvedText.contains("US"), "ExpressionResolver should resolve user attributes")
    try expect(resolvedText.contains("#111111"), "ExpressionResolver should resolve theme values")

    let condition = ComponentCondition(field: "user.country", operator: "is", value: .string("US"))
    try expect(
        ConditionEvaluator.evaluate(
            condition: condition,
            products: decodedPaywall.products,
            selectedProductIndex: 0,
            userAttributes: ["country": "US"],
            theme: decodedPaywall.theme
        ),
        "ConditionEvaluator should evaluate matching user conditions"
    )

    CustomViewRegistry.shared.unregisterAll()
    CustomViewRegistry.shared.register(name: "HeroBanner") { Text("Hero") }
    try expect(CustomViewRegistry.shared.isRegistered(name: "HeroBanner"), "CustomViewRegistry should register views")
    CustomViewRegistry.shared.unregister(name: "HeroBanner")
    try expect(!CustomViewRegistry.shared.isRegistered(name: "HeroBanner"), "CustomViewRegistry should unregister views")

    let config = SDKConfig(campaigns: [campaign], paywalls: ["paywall_1": paywall], products: [product])
    let configData = try JSONEncoder().encode(config)
    let decodedConfig = try JSONDecoder().decode(SDKConfig.self, from: configData)
    let placementStore = AssignmentStore(defaults: defaults)
    let result = PlacementEvaluator.evaluate(
        placement: "feature_gate",
        config: decodedConfig,
        context: [
            "user": ["country": "US", "id": "user_1", "seed": 1],
            "device": ["platform": "ios"],
            "platform": "ios",
        ],
        userId: "user_1",
        entitlements: [],
        assignmentStore: placementStore
    )
    try expect(result?.paywallId == "paywall_1", "PlacementEvaluator should resolve matching paywalls")

    let preview = PaywallView(schema: paywall)
    let mirror = Mirror(reflecting: preview)
    try expect(!mirror.children.isEmpty, "PaywallView should initialize")

    try expectThrows("Unknown placement should not produce a result") {
        let missing = PlacementEvaluator.evaluate(
            placement: "missing",
            config: decodedConfig,
            context: [:],
            userId: "user_1",
            entitlements: [],
            assignmentStore: placementStore
        )
        if missing == nil {
            throw NSError(domain: "ExpectedFailure", code: 0)
        }
    }
}

do {
    if #available(iOS 16.0, macOS 13.0, *) {
        try runHarness()
        print("AgentWallie library harness passed")
    } else {
        fputs("AgentWallie library harness requires macOS 13+\n", stderr)
        exit(1)
    }
} catch {
    fputs("AgentWallie library harness failed: \(error)\n", stderr)
    exit(1)
}
