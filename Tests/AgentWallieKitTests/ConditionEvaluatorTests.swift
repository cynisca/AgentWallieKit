import XCTest
@testable import AgentWallieKit

@available(iOS 16.0, *)
final class ConditionEvaluatorTests: XCTestCase {

    private let products: [ProductSlot] = [
        ProductSlot(slot: "primary", label: "Monthly", productId: "com.app.monthly"),
        ProductSlot(slot: "secondary", label: "Yearly", productId: "com.app.yearly"),
    ]

    private let theme = PaywallTheme()

    // MARK: - Nil Condition

    func testNilConditionReturnsTrue() {
        XCTAssertTrue(ConditionEvaluator.evaluate(
            condition: nil,
            products: products,
            selectedProductIndex: 0,
            userAttributes: nil,
            theme: theme
        ))
    }

    // MARK: - Is Operator

    func testIsOperatorMatch() {
        let condition = ComponentCondition(
            field: "products.selected.slot",
            operator: "is",
            value: .string("primary")
        )
        XCTAssertTrue(ConditionEvaluator.evaluate(
            condition: condition,
            products: products,
            selectedProductIndex: 0,
            userAttributes: nil,
            theme: theme
        ))
    }

    func testIsOperatorMismatch() {
        let condition = ComponentCondition(
            field: "products.selected.slot",
            operator: "is",
            value: .string("secondary")
        )
        XCTAssertFalse(ConditionEvaluator.evaluate(
            condition: condition,
            products: products,
            selectedProductIndex: 0,
            userAttributes: nil,
            theme: theme
        ))
    }

    // MARK: - Is Not Operator

    func testIsNotOperator() {
        let condition = ComponentCondition(
            field: "products.selected.slot",
            operator: "is_not",
            value: .string("secondary")
        )
        XCTAssertTrue(ConditionEvaluator.evaluate(
            condition: condition,
            products: products,
            selectedProductIndex: 0,
            userAttributes: nil,
            theme: theme
        ))
    }

    func testIsNotOperatorFails() {
        let condition = ComponentCondition(
            field: "products.selected.slot",
            operator: "is_not",
            value: .string("primary")
        )
        XCTAssertFalse(ConditionEvaluator.evaluate(
            condition: condition,
            products: products,
            selectedProductIndex: 0,
            userAttributes: nil,
            theme: theme
        ))
    }

    // MARK: - Numeric Comparisons

    func testGtOperator() {
        let condition = ComponentCondition(
            field: "user.session_count",
            operator: "gt",
            value: .number(5)
        )
        XCTAssertTrue(ConditionEvaluator.evaluate(
            condition: condition,
            products: nil,
            selectedProductIndex: 0,
            userAttributes: ["session_count": 10],
            theme: nil
        ))
        XCTAssertFalse(ConditionEvaluator.evaluate(
            condition: condition,
            products: nil,
            selectedProductIndex: 0,
            userAttributes: ["session_count": 5],
            theme: nil
        ))
    }

    func testGteOperator() {
        let condition = ComponentCondition(
            field: "user.session_count",
            operator: "gte",
            value: .number(5)
        )
        XCTAssertTrue(ConditionEvaluator.evaluate(
            condition: condition,
            products: nil,
            selectedProductIndex: 0,
            userAttributes: ["session_count": 5],
            theme: nil
        ))
        XCTAssertFalse(ConditionEvaluator.evaluate(
            condition: condition,
            products: nil,
            selectedProductIndex: 0,
            userAttributes: ["session_count": 4],
            theme: nil
        ))
    }

    func testLtOperator() {
        let condition = ComponentCondition(
            field: "user.age",
            operator: "lt",
            value: .number(18)
        )
        XCTAssertTrue(ConditionEvaluator.evaluate(
            condition: condition,
            products: nil,
            selectedProductIndex: 0,
            userAttributes: ["age": 15],
            theme: nil
        ))
        XCTAssertFalse(ConditionEvaluator.evaluate(
            condition: condition,
            products: nil,
            selectedProductIndex: 0,
            userAttributes: ["age": 18],
            theme: nil
        ))
    }

    func testLteOperator() {
        let condition = ComponentCondition(
            field: "user.age",
            operator: "lte",
            value: .number(18)
        )
        XCTAssertTrue(ConditionEvaluator.evaluate(
            condition: condition,
            products: nil,
            selectedProductIndex: 0,
            userAttributes: ["age": 18],
            theme: nil
        ))
        XCTAssertFalse(ConditionEvaluator.evaluate(
            condition: condition,
            products: nil,
            selectedProductIndex: 0,
            userAttributes: ["age": 19],
            theme: nil
        ))
    }

    // MARK: - Contains Operator

    func testContainsOperator() {
        let condition = ComponentCondition(
            field: "user.email",
            operator: "contains",
            value: .string("@gmail")
        )
        XCTAssertTrue(ConditionEvaluator.evaluate(
            condition: condition,
            products: nil,
            selectedProductIndex: 0,
            userAttributes: ["email": "user@gmail.com"],
            theme: nil
        ))
        XCTAssertFalse(ConditionEvaluator.evaluate(
            condition: condition,
            products: nil,
            selectedProductIndex: 0,
            userAttributes: ["email": "user@yahoo.com"],
            theme: nil
        ))
    }

    // MARK: - Exists / Not Exists

    func testExistsOperator() {
        let condition = ComponentCondition(
            field: "user.name",
            operator: "exists",
            value: nil
        )
        XCTAssertTrue(ConditionEvaluator.evaluate(
            condition: condition,
            products: nil,
            selectedProductIndex: 0,
            userAttributes: ["name": "Fahim"],
            theme: nil
        ))
        XCTAssertFalse(ConditionEvaluator.evaluate(
            condition: condition,
            products: nil,
            selectedProductIndex: 0,
            userAttributes: [:],
            theme: nil
        ))
    }

    func testNotExistsOperator() {
        let condition = ComponentCondition(
            field: "user.premium",
            operator: "not_exists",
            value: nil
        )
        XCTAssertTrue(ConditionEvaluator.evaluate(
            condition: condition,
            products: nil,
            selectedProductIndex: 0,
            userAttributes: [:],
            theme: nil
        ))
        XCTAssertFalse(ConditionEvaluator.evaluate(
            condition: condition,
            products: nil,
            selectedProductIndex: 0,
            userAttributes: ["premium": true],
            theme: nil
        ))
    }

    // MARK: - User Field Resolution

    func testUserFieldResolution() {
        let condition = ComponentCondition(
            field: "user.plan",
            operator: "is",
            value: .string("pro")
        )
        XCTAssertTrue(ConditionEvaluator.evaluate(
            condition: condition,
            products: nil,
            selectedProductIndex: 0,
            userAttributes: ["plan": "pro"],
            theme: nil
        ))
    }

    // MARK: - Unknown Field

    func testUnknownFieldReturnsFalse() {
        let condition = ComponentCondition(
            field: "nonexistent.path",
            operator: "is",
            value: .string("something")
        )
        XCTAssertFalse(ConditionEvaluator.evaluate(
            condition: condition,
            products: products,
            selectedProductIndex: 0,
            userAttributes: nil,
            theme: theme
        ))
    }

    // MARK: - Product Slot Resolution

    func testProductSlotResolution() {
        let condition = ComponentCondition(
            field: "products.primary.label",
            operator: "is",
            value: .string("Monthly")
        )
        XCTAssertTrue(ConditionEvaluator.evaluate(
            condition: condition,
            products: products,
            selectedProductIndex: 0,
            userAttributes: nil,
            theme: nil
        ))
    }
}
