import XCTest
@testable import AgentWallieKit

final class CampaignModelTests: XCTestCase {

    // MARK: - Helper

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Campaign

    func testCampaignEncodingDecoding() throws {
        let campaign = Campaign(
            id: "c1",
            name: "Spring Sale",
            status: .active,
            placements: [
                Placement(id: "p1", name: "onboarding", type: .custom, status: .active),
                Placement(id: "p2", name: "home", type: .standard, status: .paused),
            ],
            audiences: [
                Audience(
                    id: "a1",
                    name: "Everyone",
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

        let decoded = try roundTrip(campaign)
        XCTAssertEqual(decoded.id, "c1")
        XCTAssertEqual(decoded.name, "Spring Sale")
        XCTAssertEqual(decoded.status, .active)
        XCTAssertEqual(decoded.placements.count, 2)
        XCTAssertEqual(decoded.audiences.count, 1)
        XCTAssertEqual(decoded.audiences[0].experiment?.id, "e1")
    }

    // MARK: - CampaignStatus

    func testCampaignStatusAllCases() throws {
        let cases: [CampaignStatus] = [.active, .inactive, .archived]
        for status in cases {
            let decoded = try roundTrip(status)
            XCTAssertEqual(decoded, status)
        }
    }

    func testCampaignStatusRawValues() {
        XCTAssertEqual(CampaignStatus.active.rawValue, "active")
        XCTAssertEqual(CampaignStatus.inactive.rawValue, "inactive")
        XCTAssertEqual(CampaignStatus.archived.rawValue, "archived")
    }

    // MARK: - Placement

    func testPlacementEncodingDecoding() throws {
        let placement = Placement(id: "p1", name: "settings", type: .custom, status: .active)
        let decoded = try roundTrip(placement)
        XCTAssertEqual(decoded.id, "p1")
        XCTAssertEqual(decoded.name, "settings")
        XCTAssertEqual(decoded.type, .custom)
        XCTAssertEqual(decoded.status, .active)
    }

    // MARK: - PlacementType

    func testPlacementTypeAllCases() throws {
        let cases: [PlacementType] = [.standard, .custom]
        for pt in cases {
            let decoded = try roundTrip(pt)
            XCTAssertEqual(decoded, pt)
        }
    }

    // MARK: - PlacementStatus

    func testPlacementStatusAllCases() throws {
        let cases: [PlacementStatus] = [.active, .paused]
        for ps in cases {
            let decoded = try roundTrip(ps)
            XCTAssertEqual(decoded, ps)
        }
    }

    // MARK: - Audience

    func testAudienceWithFiltersRoundTrip() throws {
        let audience = Audience(
            id: "a1",
            name: "Power Users",
            priorityOrder: 2,
            filters: [
                AudienceFilter(field: "session_count", operator: .gte, value: .int(10)),
                AudienceFilter(field: "country", operator: .in, value: .stringArray(["US", "CA"]), conjunction: .and),
            ]
        )
        let decoded = try roundTrip(audience)
        XCTAssertEqual(decoded.id, "a1")
        XCTAssertEqual(decoded.name, "Power Users")
        XCTAssertEqual(decoded.priorityOrder, 2)
        XCTAssertEqual(decoded.filters.count, 2)
        XCTAssertEqual(decoded.filters[0].field, "session_count")
        XCTAssertEqual(decoded.filters[0].operator, .gte)
        XCTAssertEqual(decoded.filters[1].conjunction, .and)
        XCTAssertNil(decoded.entitlementCheck)
        XCTAssertNil(decoded.frequencyCap)
        XCTAssertNil(decoded.experiment)
    }

    func testAudienceWithEntitlementCheckAndFrequencyCap() throws {
        let audience = Audience(
            id: "a2",
            name: "Non-Premium",
            priorityOrder: 0,
            filters: [],
            entitlementCheck: "premium",
            frequencyCap: FrequencyCap(type: .oncePerDay, limit: nil)
        )
        let decoded = try roundTrip(audience)
        XCTAssertEqual(decoded.entitlementCheck, "premium")
        XCTAssertEqual(decoded.frequencyCap?.type, .oncePerDay)
        XCTAssertNil(decoded.frequencyCap?.limit)
    }

    // MARK: - AudienceFilter operators

    func testAudienceFilterWithEachOperator() throws {
        let operators: [(FilterOperator, FilterValue)] = [
            (.is, .string("free")),
            (.isNot, .string("pro")),
            (.contains, .string("gmail")),
            (.gt, .int(5)),
            (.gte, .int(3)),
            (.lt, .double(100.0)),
            (.lte, .double(99.9)),
            (.in, .stringArray(["US", "CA"])),
            (.notIn, .stringArray(["CN"])),
            (.exists, .bool(true)),
            (.notExists, .bool(true)),
        ]

        for (op, value) in operators {
            let filter = AudienceFilter(field: "test", operator: op, value: value)
            let decoded = try roundTrip(filter)
            XCTAssertEqual(decoded.operator, op, "Failed for operator \(op)")
        }
    }

    // MARK: - FilterValue types

    func testFilterValueString() throws {
        let v = FilterValue.string("hello")
        let decoded = try roundTrip(v)
        XCTAssertEqual(decoded.stringValue, "hello")
        XCTAssertNil(decoded.doubleValue)
        XCTAssertNil(decoded.arrayValue)
    }

    func testFilterValueInt() throws {
        let v = FilterValue.int(42)
        let decoded = try roundTrip(v)
        // Note: int may decode as int or double depending on JSON
        XCTAssertNotNil(decoded.doubleValue)
        XCTAssertEqual(decoded.doubleValue, 42.0)
    }

    func testFilterValueDouble() throws {
        let v = FilterValue.double(3.14)
        let decoded = try roundTrip(v)
        XCTAssertNotNil(decoded.doubleValue)
        XCTAssertEqual(decoded.doubleValue!, 3.14, accuracy: 0.001)
    }

    func testFilterValueBool() throws {
        let v = FilterValue.bool(true)
        let decoded = try roundTrip(v)
        if case .bool(let b) = decoded {
            XCTAssertTrue(b)
        } else {
            XCTFail("Expected bool FilterValue")
        }
    }

    func testFilterValueStringArray() throws {
        let v = FilterValue.stringArray(["a", "b", "c"])
        let decoded = try roundTrip(v)
        XCTAssertEqual(decoded.arrayValue, ["a", "b", "c"])
    }

    // MARK: - FilterValue.isEqual()

    func testFilterValueIsEqualString() {
        let v = FilterValue.string("test")
        XCTAssertTrue(v.isEqual(to: "test"))
        XCTAssertFalse(v.isEqual(to: "other"))
        XCTAssertFalse(v.isEqual(to: 42))
    }

    func testFilterValueIsEqualInt() {
        let v = FilterValue.int(42)
        XCTAssertTrue(v.isEqual(to: 42))
        XCTAssertTrue(v.isEqual(to: 42.0)) // int vs double comparison
        XCTAssertFalse(v.isEqual(to: 43))
        XCTAssertFalse(v.isEqual(to: "42"))
    }

    func testFilterValueIsEqualDouble() {
        let v = FilterValue.double(3.14)
        XCTAssertTrue(v.isEqual(to: 3.14))
        XCTAssertFalse(v.isEqual(to: 3.15))
        XCTAssertFalse(v.isEqual(to: "3.14"))
    }

    func testFilterValueIsEqualBool() {
        let v = FilterValue.bool(true)
        XCTAssertTrue(v.isEqual(to: true))
        XCTAssertFalse(v.isEqual(to: false))
        XCTAssertFalse(v.isEqual(to: "true"))
    }

    func testFilterValueIsEqualStringArray() {
        let v = FilterValue.stringArray(["a", "b"])
        // stringArray always returns false from isEqual
        XCTAssertFalse(v.isEqual(to: ["a", "b"]))
    }

    // MARK: - FilterValue.doubleValue

    func testFilterValueDoubleValueForInt() {
        XCTAssertEqual(FilterValue.int(10).doubleValue, 10.0)
    }

    func testFilterValueDoubleValueForDouble() {
        XCTAssertEqual(FilterValue.double(2.5).doubleValue, 2.5)
    }

    func testFilterValueDoubleValueForNonNumeric() {
        XCTAssertNil(FilterValue.string("hello").doubleValue)
        XCTAssertNil(FilterValue.bool(true).doubleValue)
        XCTAssertNil(FilterValue.stringArray(["a"]).doubleValue)
    }

    // MARK: - FilterConjunction

    func testFilterConjunctionAllCases() throws {
        let cases: [FilterConjunction] = [.and, .or]
        for c in cases {
            let decoded = try roundTrip(c)
            XCTAssertEqual(decoded, c)
        }
    }

    // MARK: - FrequencyCap

    func testFrequencyCapEncodingDecoding() throws {
        let cap = FrequencyCap(type: .nTimesTotal, limit: 5)
        let decoded = try roundTrip(cap)
        XCTAssertEqual(decoded.type, .nTimesTotal)
        XCTAssertEqual(decoded.limit, 5)
    }

    func testFrequencyCapWithoutLimit() throws {
        let cap = FrequencyCap(type: .unlimited)
        let decoded = try roundTrip(cap)
        XCTAssertEqual(decoded.type, .unlimited)
        XCTAssertNil(decoded.limit)
    }

    // MARK: - FrequencyCapType

    func testFrequencyCapTypeAllCases() throws {
        let cases: [FrequencyCapType] = [.oncePerSession, .oncePerDay, .nTimesTotal, .unlimited]
        for fct in cases {
            let decoded = try roundTrip(fct)
            XCTAssertEqual(decoded, fct)
        }
    }

    func testFrequencyCapTypeRawValues() {
        XCTAssertEqual(FrequencyCapType.oncePerSession.rawValue, "once_per_session")
        XCTAssertEqual(FrequencyCapType.oncePerDay.rawValue, "once_per_day")
        XCTAssertEqual(FrequencyCapType.nTimesTotal.rawValue, "n_times_total")
        XCTAssertEqual(FrequencyCapType.unlimited.rawValue, "unlimited")
    }

    // MARK: - Experiment

    func testExperimentWithVariantsRoundTrip() throws {
        let experiment = Experiment(
            id: "exp1",
            variants: [
                ExperimentVariant(id: "v1", paywallId: "pw1", trafficPercentage: 60),
                ExperimentVariant(id: "v2", paywallId: "pw2", trafficPercentage: 40),
            ],
            holdoutPercentage: 10,
            status: .running
        )
        let decoded = try roundTrip(experiment)
        XCTAssertEqual(decoded.id, "exp1")
        XCTAssertEqual(decoded.variants.count, 2)
        XCTAssertEqual(decoded.variants[0].id, "v1")
        XCTAssertEqual(decoded.variants[0].paywallId, "pw1")
        XCTAssertEqual(decoded.variants[0].trafficPercentage, 60)
        XCTAssertEqual(decoded.variants[1].trafficPercentage, 40)
        XCTAssertEqual(decoded.holdoutPercentage, 10)
        XCTAssertEqual(decoded.status, .running)
    }

    // MARK: - ExperimentStatus

    func testExperimentStatusAllCases() throws {
        let cases: [ExperimentStatus] = [.running, .paused, .completed]
        for es in cases {
            let decoded = try roundTrip(es)
            XCTAssertEqual(decoded, es)
        }
    }

    // MARK: - ExperimentVariant

    func testExperimentVariantEncodingDecoding() throws {
        let variant = ExperimentVariant(id: "v1", paywallId: "pw_abc", trafficPercentage: 75)
        let decoded = try roundTrip(variant)
        XCTAssertEqual(decoded.id, "v1")
        XCTAssertEqual(decoded.paywallId, "pw_abc")
        XCTAssertEqual(decoded.trafficPercentage, 75)
    }

    func testExperimentVariantSnakeCaseKeys() throws {
        let json = """
        {"id": "v1", "paywall_id": "pw1", "traffic_percentage": 50}
        """
        let data = json.data(using: .utf8)!
        let variant = try JSONDecoder().decode(ExperimentVariant.self, from: data)
        XCTAssertEqual(variant.paywallId, "pw1")
        XCTAssertEqual(variant.trafficPercentage, 50)
    }

    // MARK: - Campaign JSON decoding

    func testCampaignFromJSON() throws {
        let json = """
        {
            "id": "c1",
            "name": "Test",
            "status": "archived",
            "placements": [
                {"id": "p1", "name": "home", "type": "standard", "status": "paused"}
            ],
            "audiences": [
                {
                    "id": "a1",
                    "name": "All",
                    "priority_order": 0,
                    "filters": [],
                    "entitlement_check": "pro",
                    "frequency_cap": {"type": "once_per_session"}
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let campaign = try JSONDecoder().decode(Campaign.self, from: data)
        XCTAssertEqual(campaign.status, .archived)
        XCTAssertEqual(campaign.placements[0].type, .standard)
        XCTAssertEqual(campaign.placements[0].status, .paused)
        XCTAssertEqual(campaign.audiences[0].entitlementCheck, "pro")
        XCTAssertEqual(campaign.audiences[0].frequencyCap?.type, .oncePerSession)
    }
}
