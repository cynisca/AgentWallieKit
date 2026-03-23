import Foundation

/// Result of evaluating a placement — which paywall to show (if any).
public struct PlacementResult: Sendable {
    public let campaignId: String
    public let audienceId: String
    public let experimentId: String?
    public let variantId: String?
    public let paywallId: String?
    public let isHoldout: Bool

    public init(
        campaignId: String,
        audienceId: String,
        experimentId: String? = nil,
        variantId: String? = nil,
        paywallId: String? = nil,
        isHoldout: Bool = false
    ) {
        self.campaignId = campaignId
        self.audienceId = audienceId
        self.experimentId = experimentId
        self.variantId = variantId
        self.paywallId = paywallId
        self.isHoldout = isHoldout
    }
}

/// Evaluates which paywall to show for a given placement.
///
/// Flow:
/// 1. Find active campaigns that have this placement active
/// 2. For each campaign, evaluate audiences top-to-bottom (by priority_order)
/// 3. For the first matching audience, check experiment assignment
/// 4. Return the paywall to show, or nil for holdout / no match
public enum PlacementEvaluator {

    public static func evaluate(
        placement: String,
        config: SDKConfig,
        context: [String: Any],
        userId: String,
        entitlements: Set<String>,
        assignmentStore: AssignmentStore
    ) -> PlacementResult? {
        #if DEBUG
        var campaignsChecked = 0
        var campaignsWithPlacement = 0
        #endif

        for campaign in config.campaigns {
            guard campaign.status == .active else { continue }
            #if DEBUG
            campaignsChecked += 1
            #endif

            let hasPlacement = campaign.placements.contains { p in
                p.name == placement && p.status == .active
            }
            guard hasPlacement else { continue }
            #if DEBUG
            campaignsWithPlacement += 1
            #endif

            let sortedAudiences = campaign.audiences.sorted { $0.priorityOrder < $1.priorityOrder }

            for audience in sortedAudiences {
                if let entitlementCheck = audience.entitlementCheck,
                   entitlements.contains(entitlementCheck) {
                    continue
                }

                let matches = FilterEngine.evaluate(filters: audience.filters, context: context)
                guard matches else { continue }

                guard let experiment = audience.experiment else {
                    log(.warn, "Audience '\(audience.name)' matched but has no experiment — no paywall to show")
                    return PlacementResult(
                        campaignId: campaign.id,
                        audienceId: audience.id,
                        isHoldout: false
                    )
                }

                guard experiment.status == .running else {
                    log(.warn, "Audience '\(audience.name)' matched but experiment status is '\(experiment.status)' — no paywall to show")
                    return PlacementResult(
                        campaignId: campaign.id,
                        audienceId: audience.id,
                        isHoldout: false
                    )
                }

                if let persisted = assignmentStore.getAssignment(
                    userId: userId,
                    experimentId: experiment.id
                ) {
                    if persisted.isHoldout {
                        return PlacementResult(
                            campaignId: campaign.id,
                            audienceId: audience.id,
                            experimentId: experiment.id,
                            isHoldout: true
                        )
                    }
                    return PlacementResult(
                        campaignId: campaign.id,
                        audienceId: audience.id,
                        experimentId: experiment.id,
                        variantId: persisted.variantId,
                        paywallId: persisted.paywallId,
                        isHoldout: false
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
                    isHoldout: assignment == nil
                )
                assignmentStore.saveAssignment(
                    userId: userId,
                    experimentId: experiment.id,
                    assignment: stored
                )

                if let assignment = assignment {
                    return PlacementResult(
                        campaignId: campaign.id,
                        audienceId: audience.id,
                        experimentId: experiment.id,
                        variantId: assignment.variantId,
                        paywallId: assignment.paywallId,
                        isHoldout: false
                    )
                } else {
                    return PlacementResult(
                        campaignId: campaign.id,
                        audienceId: audience.id,
                        experimentId: experiment.id,
                        isHoldout: true
                    )
                }
            }
        }

        #if DEBUG
        log(.warn, "No match for placement '\(placement)': checked \(campaignsChecked) active campaigns, \(campaignsWithPlacement) had this placement")
        #endif
        return nil
    }

    private static func log(_ level: LogLevel, _ message: @autoclosure () -> String) {
        AWLogger.log(level, message())
    }
}
