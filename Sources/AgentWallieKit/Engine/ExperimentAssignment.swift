import Foundation

/// Result of assigning a user to an experiment variant.
public struct AssignmentResult: Equatable, Sendable {
    public let variantId: String
    public let paywallId: String

    public init(variantId: String, paywallId: String) {
        self.variantId = variantId
        self.paywallId = paywallId
    }
}

/// Deterministic experiment variant assignment based on a hash of userId + experimentId.
/// Mirrors the shared TypeScript experiment-assignment module.
public enum ExperimentAssignment {

    /// Assigns a user to an experiment variant deterministically.
    ///
    /// - Parameters:
    ///   - userId: The user identifier
    ///   - experimentId: The experiment identifier
    ///   - variants: Array of variants with traffic percentages
    ///   - holdoutPercentage: Percentage of traffic in holdout (no paywall)
    /// - Returns: The assigned variant, or nil if the user falls in the holdout group
    public static func assignVariant(
        userId: String,
        experimentId: String,
        variants: [ExperimentVariant],
        holdoutPercentage: Int
    ) -> AssignmentResult? {
        let bucket = hashString("\(userId):\(experimentId)") % 100

        var cumulative = 0
        for variant in variants {
            cumulative += variant.trafficPercentage
            if bucket < cumulative {
                return AssignmentResult(
                    variantId: variant.id,
                    paywallId: variant.paywallId
                )
            }
        }

        // Bucket falls in holdout range (or past all variant ranges)
        return nil
    }

    /// djb2 hash algorithm — matches the TypeScript implementation exactly.
    /// Returns an unsigned integer.
    static func hashString(_ str: String) -> Int {
        var hash: UInt32 = 5381
        for char in str.utf8 {
            // hash = ((hash << 5) + hash + charCode) >>> 0
            hash = (hash &<< 5) &+ hash &+ UInt32(char)
        }
        return Int(hash)
    }
}
