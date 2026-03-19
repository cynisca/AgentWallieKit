import XCTest
@testable import AgentWallieKit

final class PlacementEvaluatorTests: XCTestCase {

    func testMatchesActiveCampaignWithPlacement() {
        let config = makeConfig(
            campaigns: [
                Campaign(
                    id: "c1",
                    name: "Test Campaign",
                    status: .active,
                    placements: [Placement(id: "p1", name: "onboarding", type: .custom, status: .active)],
                    audiences: [
                        Audience(
                            id: "a1",
                            name: "Everyone",
                            priorityOrder: 0,
                            filters: [],
                            experiment: Experiment(
                                id: "e1",
                                variants: [ExperimentVariant(id: "v1", paywallId: "pw1", trafficPercentage: 100)],
                                holdoutPercentage: 0,
                                status: .running
                            )
                        )
                    ]
                )
            ],
            paywalls: ["pw1": makePaywall(name: "test")]
        )

        let store = AssignmentStore(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
        let result = PlacementEvaluator.evaluate(
            placement: "onboarding",
            config: config,
            context: [:],
            userId: "user-1",
            entitlements: [],
            assignmentStore: store
        )

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.campaignId, "c1")
        XCTAssertEqual(result?.paywallId, "pw1")
        XCTAssertFalse(result?.isHoldout ?? true)
    }

    func testSkipsInactiveCampaign() {
        let config = makeConfig(
            campaigns: [
                Campaign(
                    id: "c1",
                    name: "Inactive",
                    status: .inactive,
                    placements: [Placement(id: "p1", name: "onboarding", type: .custom, status: .active)],
                    audiences: [
                        Audience(id: "a1", name: "Everyone", priorityOrder: 0, filters: [])
                    ]
                )
            ]
        )

        let store = AssignmentStore(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
        let result = PlacementEvaluator.evaluate(
            placement: "onboarding", config: config, context: [:],
            userId: "user-1", entitlements: [], assignmentStore: store
        )
        XCTAssertNil(result)
    }

    func testSkipsPausedPlacement() {
        let config = makeConfig(
            campaigns: [
                Campaign(
                    id: "c1",
                    name: "Test",
                    status: .active,
                    placements: [Placement(id: "p1", name: "onboarding", type: .custom, status: .paused)],
                    audiences: [
                        Audience(id: "a1", name: "Everyone", priorityOrder: 0, filters: [])
                    ]
                )
            ]
        )

        let store = AssignmentStore(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
        let result = PlacementEvaluator.evaluate(
            placement: "onboarding", config: config, context: [:],
            userId: "user-1", entitlements: [], assignmentStore: store
        )
        XCTAssertNil(result)
    }

    func testAudienceFilterEvaluation() {
        let config = makeConfig(
            campaigns: [
                Campaign(
                    id: "c1",
                    name: "Premium Campaign",
                    status: .active,
                    placements: [Placement(id: "p1", name: "upgrade", type: .custom, status: .active)],
                    audiences: [
                        Audience(
                            id: "a1",
                            name: "Free Users",
                            priorityOrder: 0,
                            filters: [
                                AudienceFilter(field: "user.plan", operator: .is, value: .string("free"))
                            ],
                            experiment: Experiment(
                                id: "e1",
                                variants: [ExperimentVariant(id: "v1", paywallId: "pw1", trafficPercentage: 100)],
                                holdoutPercentage: 0,
                                status: .running
                            )
                        )
                    ]
                )
            ],
            paywalls: ["pw1": makePaywall(name: "upgrade")]
        )

        let store = AssignmentStore(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)

        // Matching context
        let matchResult = PlacementEvaluator.evaluate(
            placement: "upgrade", config: config,
            context: ["user": ["plan": "free"]],
            userId: "user-1", entitlements: [], assignmentStore: store
        )
        XCTAssertNotNil(matchResult)

        // Non-matching context
        let noMatchResult = PlacementEvaluator.evaluate(
            placement: "upgrade", config: config,
            context: ["user": ["plan": "pro"]],
            userId: "user-2", entitlements: [], assignmentStore: store
        )
        XCTAssertNil(noMatchResult)
    }

    func testAudiencePriorityOrder() {
        let config = makeConfig(
            campaigns: [
                Campaign(
                    id: "c1",
                    name: "Test",
                    status: .active,
                    placements: [Placement(id: "p1", name: "home", type: .custom, status: .active)],
                    audiences: [
                        Audience(
                            id: "a2",
                            name: "Second",
                            priorityOrder: 1,
                            filters: [],
                            experiment: Experiment(
                                id: "e2",
                                variants: [ExperimentVariant(id: "v2", paywallId: "pw2", trafficPercentage: 100)],
                                holdoutPercentage: 0,
                                status: .running
                            )
                        ),
                        Audience(
                            id: "a1",
                            name: "First",
                            priorityOrder: 0,
                            filters: [],
                            experiment: Experiment(
                                id: "e1",
                                variants: [ExperimentVariant(id: "v1", paywallId: "pw1", trafficPercentage: 100)],
                                holdoutPercentage: 0,
                                status: .running
                            )
                        ),
                    ]
                )
            ],
            paywalls: [
                "pw1": makePaywall(name: "first"),
                "pw2": makePaywall(name: "second"),
            ]
        )

        let store = AssignmentStore(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
        let result = PlacementEvaluator.evaluate(
            placement: "home", config: config, context: [:],
            userId: "user-1", entitlements: [], assignmentStore: store
        )

        // Should match the audience with priorityOrder=0 (a1), which uses pw1
        XCTAssertEqual(result?.audienceId, "a1")
        XCTAssertEqual(result?.paywallId, "pw1")
    }

    func testEntitlementCheckSkipsAudience() {
        let config = makeConfig(
            campaigns: [
                Campaign(
                    id: "c1",
                    name: "Test",
                    status: .active,
                    placements: [Placement(id: "p1", name: "upgrade", type: .custom, status: .active)],
                    audiences: [
                        Audience(
                            id: "a1",
                            name: "Non-Pro",
                            priorityOrder: 0,
                            filters: [],
                            entitlementCheck: "pro"
                        )
                    ]
                )
            ]
        )

        let store = AssignmentStore(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)

        // User has "pro" entitlement — audience should be skipped
        let result = PlacementEvaluator.evaluate(
            placement: "upgrade", config: config, context: [:],
            userId: "user-1", entitlements: ["pro"], assignmentStore: store
        )
        XCTAssertNil(result)
    }

    // MARK: - Helpers

    private func makeConfig(campaigns: [Campaign], paywalls: [String: PaywallSchema] = [:]) -> SDKConfig {
        SDKConfig(campaigns: campaigns, paywalls: paywalls)
    }

    private func makePaywall(name: String) -> PaywallSchema {
        PaywallSchema(
            version: "1.0",
            name: name,
            settings: PaywallSettings(),
            components: []
        )
    }
}
