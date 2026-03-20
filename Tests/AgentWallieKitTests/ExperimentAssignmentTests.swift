import XCTest
@testable import AgentWallieKit

final class ExperimentAssignmentTests: XCTestCase {

    let variants = [
        ExperimentVariant(id: "v1", paywallId: "pw1", trafficPercentage: 50),
        ExperimentVariant(id: "v2", paywallId: "pw2", trafficPercentage: 30),
    ]

    func testReturnsVariantOrNull() {
        let result = ExperimentAssignment.assignVariant(
            userId: "user-1", experimentId: "exp-1", variants: variants, holdoutPercentage: 20
        )
        if let r = result {
            XCTAssertFalse(r.variantId.isEmpty)
            XCTAssertFalse(r.paywallId.isEmpty)
        }
        // nil is also valid (holdout)
    }

    func testSameUserAlwaysGetsSameVariant() {
        var results: [AssignmentResult?] = []
        for _ in 0..<100 {
            results.append(
                ExperimentAssignment.assignVariant(
                    userId: "stable-user", experimentId: "exp-1",
                    variants: variants, holdoutPercentage: 20
                )
            )
        }
        let first = results[0]
        for r in results {
            XCTAssertEqual(r, first)
        }
    }

    func testDifferentExperimentsCanAssignDifferently() {
        var diffCount = 0
        for i in 0..<100 {
            let r1 = ExperimentAssignment.assignVariant(
                userId: "user-\(i)", experimentId: "exp-A",
                variants: variants, holdoutPercentage: 20
            )
            let r2 = ExperimentAssignment.assignVariant(
                userId: "user-\(i)", experimentId: "exp-B",
                variants: variants, holdoutPercentage: 20
            )
            if r1?.variantId != r2?.variantId { diffCount += 1 }
        }
        XCTAssertGreaterThan(diffCount, 0)
    }

    func testRespectsTrafficPercentages() {
        var counts: [String: Int] = ["v1": 0, "v2": 0, "holdout": 0]
        let n = 10000

        for i in 0..<n {
            let result = ExperimentAssignment.assignVariant(
                userId: "user-\(i)", experimentId: "exp-dist",
                variants: variants, holdoutPercentage: 20
            )
            if let r = result {
                counts[r.variantId, default: 0] += 1
            } else {
                counts["holdout", default: 0] += 1
            }
        }

        // Expected: v1=50%, v2=30%, holdout=20% — allow +/- 5%
        let v1Pct = Double(counts["v1"]!) / Double(n)
        let v2Pct = Double(counts["v2"]!) / Double(n)
        let holdoutPct = Double(counts["holdout"]!) / Double(n)

        XCTAssertEqual(v1Pct, 0.5, accuracy: 0.05)
        XCTAssertEqual(v2Pct, 0.3, accuracy: 0.05)
        XCTAssertEqual(holdoutPct, 0.2, accuracy: 0.05)
    }

    func testHoldoutGroupGetsNil() {
        let allHoldoutVariants = [
            ExperimentVariant(id: "v1", paywallId: "pw1", trafficPercentage: 0)
        ]
        for i in 0..<50 {
            let result = ExperimentAssignment.assignVariant(
                userId: "user-\(i)", experimentId: "exp-holdout",
                variants: allHoldoutVariants, holdoutPercentage: 100
            )
            XCTAssertNil(result)
        }
    }

    func testZeroHoldoutMeansAllTrafficGoesToVariants() {
        let fullVariants = [
            ExperimentVariant(id: "v1", paywallId: "pw1", trafficPercentage: 60),
            ExperimentVariant(id: "v2", paywallId: "pw2", trafficPercentage: 40),
        ]
        for i in 0..<100 {
            let result = ExperimentAssignment.assignVariant(
                userId: "user-\(i)", experimentId: "exp-no-holdout",
                variants: fullVariants, holdoutPercentage: 0
            )
            XCTAssertNotNil(result)
        }
    }

    func testSingleVariant100Percent() {
        let single = [
            ExperimentVariant(id: "v1", paywallId: "pw1", trafficPercentage: 100)
        ]
        for i in 0..<100 {
            let result = ExperimentAssignment.assignVariant(
                userId: "user-\(i)", experimentId: "exp-single",
                variants: single, holdoutPercentage: 0
            )
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.variantId, "v1")
            XCTAssertEqual(result?.paywallId, "pw1")
        }
    }

    func testEmptyVariantsArray() {
        for i in 0..<20 {
            let result = ExperimentAssignment.assignVariant(
                userId: "user-\(i)", experimentId: "exp-empty",
                variants: [], holdoutPercentage: 100
            )
            XCTAssertNil(result)
        }
    }
}
