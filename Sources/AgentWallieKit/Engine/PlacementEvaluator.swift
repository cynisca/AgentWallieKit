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

    /// Evaluate a placement and return the result.
    ///
    /// - Parameters:
    ///   - placement: The placement name (e.g. "caffeineLogged")
    ///   - config: The compiled SDK config
    ///   - context: User/device/event context for filter evaluation
    ///   - userId: Current user ID for experiment assignment
    ///   - entitlements: Current user entitlements
    ///   - assignmentStore: Persisted experiment assignments
    /// - Returns: The placement result, or nil if no campaign/audience matches
    public static func evaluate(
        placement: String,
        config: SDKConfig,
        context: [String: Any],
        userId: String,
        entitlements: Set<String>,
        assignmentStore: AssignmentStore
    ) -> PlacementResult? {
        // Iterate active campaigns
        for campaign in config.campaigns {
            guard campaign.status == .active else { continue }

            // Check if this campaign has the placement active
            let hasPlacement = campaign.placements.contains { p in
                p.name == placement && p.status == .active
            }
            guard hasPlacement else { continue }

            // Evaluate audiences top-to-bottom by priority
            let sortedAudiences = campaign.audiences.sorted { $0.priorityOrder < $1.priorityOrder }

            for audience in sortedAudiences {
                // Check entitlement skip
                if let entitlementCheck = audience.entitlementCheck,
                   entitlements.contains(entitlementCheck) {
                    continue
                }

                // Evaluate audience filters
                let matches = FilterEngine.evaluate(filters: audience.filters, context: context)
                guard matches else { continue }

                // Audience matched — check experiment
                guard let experiment = audience.experiment, experiment.status == .running else {
                    // No experiment — no paywall to show for this audience
                    return PlacementResult(
                        campaignId: campaign.id,
                        audienceId: audience.id,
                        isHoldout: false
                    )
                }

                // Check for persisted assignment first
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

                // Assign variant
                let assignment = ExperimentAssignment.assignVariant(
                    userId: userId,
                    experimentId: experiment.id,
                    variants: experiment.variants,
                    holdoutPercentage: experiment.holdoutPercentage
                )

                // Persist assignment
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

        return nil
    }
}
