import XCTest
@testable import AgentWallieKit

final class FilterEngineTests: XCTestCase {

    // MARK: - Individual Operators

    func testIsOperatorMatchesExactValue() {
        let filters: [AudienceFilter] = [
            AudienceFilter(field: "status", operator: .is, value: .string("free"))
        ]
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: ["status": "free"]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: ["status": "pro"]))
    }

    func testIsNotOperatorExcludesValue() {
        let filters: [AudienceFilter] = [
            AudienceFilter(field: "status", operator: .isNot, value: .string("pro"))
        ]
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: ["status": "free"]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: ["status": "pro"]))
    }

    func testContainsOperator() {
        let filters: [AudienceFilter] = [
            AudienceFilter(field: "email", operator: .contains, value: .string("@gmail"))
        ]
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: ["email": "user@gmail.com"]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: ["email": "user@yahoo.com"]))
    }

    func testGtOperator() {
        let filters: [AudienceFilter] = [
            AudienceFilter(field: "age", operator: .gt, value: .int(18))
        ]
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: ["age": 25]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: ["age": 18]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: ["age": 10]))
    }

    func testGteOperator() {
        let filters: [AudienceFilter] = [
            AudienceFilter(field: "session_count", operator: .gte, value: .int(3))
        ]
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: ["session_count": 3]))
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: ["session_count": 5]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: ["session_count": 2]))
    }

    func testLtOperator() {
        let filters: [AudienceFilter] = [
            AudienceFilter(field: "score", operator: .lt, value: .int(50))
        ]
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: ["score": 30]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: ["score": 50]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: ["score": 80]))
    }

    func testLteOperator() {
        let filters: [AudienceFilter] = [
            AudienceFilter(field: "seed", operator: .lte, value: .int(49))
        ]
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: ["seed": 49]))
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: ["seed": 0]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: ["seed": 50]))
    }

    func testInOperator() {
        let filters: [AudienceFilter] = [
            AudienceFilter(field: "country", operator: .in, value: .stringArray(["US", "CA", "UK"]))
        ]
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: ["country": "US"]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: ["country": "DE"]))
    }

    func testNotInOperator() {
        let filters: [AudienceFilter] = [
            AudienceFilter(field: "country", operator: .notIn, value: .stringArray(["CN", "RU"]))
        ]
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: ["country": "US"]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: ["country": "CN"]))
    }

    func testExistsOperator() {
        let filters: [AudienceFilter] = [
            AudienceFilter(field: "email", operator: .exists, value: .bool(true))
        ]
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: ["email": "a@b.com"]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: [:]))
    }

    func testNotExistsOperator() {
        let filters: [AudienceFilter] = [
            AudienceFilter(field: "premium", operator: .notExists, value: .bool(true))
        ]
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: [:]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: ["premium": true]))
    }

    // MARK: - Conjunctions

    func testAndConjunctionRequiresAllConditions() {
        let filters: [AudienceFilter] = [
            AudienceFilter(field: "status", operator: .is, value: .string("free")),
            AudienceFilter(field: "session_count", operator: .gte, value: .int(3), conjunction: .and),
        ]
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: ["status": "free", "session_count": 5]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: ["status": "free", "session_count": 1]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: ["status": "pro", "session_count": 5]))
    }

    func testOrConjunctionRequiresAnyCondition() {
        let filters: [AudienceFilter] = [
            AudienceFilter(field: "status", operator: .is, value: .string("free")),
            AudienceFilter(field: "status", operator: .is, value: .string("trial"), conjunction: .or),
        ]
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: ["status": "free"]))
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: ["status": "trial"]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: ["status": "pro"]))
    }

    func testMixedAndOrConjunctions() {
        // (status=free AND session_count>=3) OR is_vip=true
        let filters: [AudienceFilter] = [
            AudienceFilter(field: "status", operator: .is, value: .string("free")),
            AudienceFilter(field: "session_count", operator: .gte, value: .int(3), conjunction: .and),
            AudienceFilter(field: "is_vip", operator: .is, value: .bool(true), conjunction: .or),
        ]
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: ["status": "free", "session_count": 5, "is_vip": false]))
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: ["status": "pro", "session_count": 0, "is_vip": true]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: ["status": "pro", "session_count": 5, "is_vip": false]))
    }

    // MARK: - Dot Notation

    func testDotNotationFieldPaths() {
        let filters: [AudienceFilter] = [
            AudienceFilter(field: "user.subscription_status", operator: .is, value: .string("free")),
            AudienceFilter(field: "device.platform", operator: .is, value: .string("ios"), conjunction: .and),
        ]
        XCTAssertTrue(FilterEngine.evaluate(filters: filters, context: [
            "user": ["subscription_status": "free"],
            "device": ["platform": "ios"],
        ]))
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: [
            "user": ["subscription_status": "pro"],
            "device": ["platform": "ios"],
        ]))
    }

    // MARK: - Edge Cases

    func testMissingFieldsReturnFalse() {
        let filters: [AudienceFilter] = [
            AudienceFilter(field: "nonexistent.field", operator: .is, value: .string("something"))
        ]
        XCTAssertFalse(FilterEngine.evaluate(filters: filters, context: [:]))
    }

    func testEmptyFiltersReturnsTrue() {
        XCTAssertTrue(FilterEngine.evaluate(filters: [], context: [:]))
    }
}
