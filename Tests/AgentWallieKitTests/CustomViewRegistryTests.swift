import XCTest
import SwiftUI
@testable import AgentWallieKit

@available(iOS 16.0, *)
final class CustomViewRegistryTests: XCTestCase {

    override func setUp() {
        super.setUp()
        CustomViewRegistry.shared.unregisterAll()
    }

    override func tearDown() {
        CustomViewRegistry.shared.unregisterAll()
        super.tearDown()
    }

    // MARK: - 1. Register simple view -> resolve returns non-nil

    func testRegisterSimpleView_resolveReturnsView() {
        CustomViewRegistry.shared.register(name: "SimpleView") {
            Text("Hello")
        }

        let context = makeContext(viewName: "SimpleView")
        let result = CustomViewRegistry.shared.resolve(name: "SimpleView", context: context)
        XCTAssertNotNil(result, "Resolving a registered simple view should return a non-nil AnyView")
    }

    // MARK: - 2. Register data builder -> context passed correctly

    func testRegisterDataBuilder_contextPassedCorrectly() {
        var receivedContext: CustomViewContext?

        CustomViewRegistry.shared.register(name: "DataView") { (ctx: CustomViewContext) -> Text in
            receivedContext = ctx
            return Text("Data View")
        }

        let theme = PaywallTheme(primary: "#FF0000")
        let products = [ProductSlot(slot: "primary", label: "Monthly", productId: "monthly_sub")]
        let customData: [String: AnyCodable] = ["title": AnyCodable("Welcome")]
        let userAttrs: [String: AnyCodable] = ["plan": AnyCodable("pro")]

        let context = CustomViewContext(
            viewName: "DataView",
            customData: customData,
            theme: theme,
            products: products,
            userAttributes: userAttrs
        )

        let result = CustomViewRegistry.shared.resolve(name: "DataView", context: context)
        XCTAssertNotNil(result)
        XCTAssertNotNil(receivedContext)
        XCTAssertEqual(receivedContext?.viewName, "DataView")
        XCTAssertEqual(receivedContext?.theme?.primary, "#FF0000")
        XCTAssertEqual(receivedContext?.products?.count, 1)
        XCTAssertEqual(receivedContext?.products?.first?.slot, "primary")
        XCTAssertEqual(receivedContext?.customData["title"]?.value as? String, "Welcome")
        XCTAssertEqual(receivedContext?.userAttributes["plan"]?.value as? String, "pro")
    }

    // MARK: - 3. Unregistered view -> resolve returns nil

    func testUnregisteredView_resolveReturnsNil() {
        let context = makeContext(viewName: "NonExistent")
        let result = CustomViewRegistry.shared.resolve(name: "NonExistent", context: context)
        XCTAssertNil(result, "Resolving an unregistered view should return nil")
    }

    // MARK: - 4. Unregister -> previously registered view returns nil

    func testUnregister_removesView() {
        CustomViewRegistry.shared.register(name: "Temp") { Text("Temp") }
        XCTAssertTrue(CustomViewRegistry.shared.isRegistered(name: "Temp"))

        CustomViewRegistry.shared.unregister(name: "Temp")
        XCTAssertFalse(CustomViewRegistry.shared.isRegistered(name: "Temp"))

        let context = makeContext(viewName: "Temp")
        XCTAssertNil(CustomViewRegistry.shared.resolve(name: "Temp", context: context))
    }

    // MARK: - 5. UnregisterAll -> all views return nil

    func testUnregisterAll_removesAllViews() {
        CustomViewRegistry.shared.register(name: "A") { Text("A") }
        CustomViewRegistry.shared.register(name: "B") { Text("B") }
        CustomViewRegistry.shared.register(name: "C") { Text("C") }
        XCTAssertEqual(CustomViewRegistry.shared.registeredNames.sorted(), ["A", "B", "C"])

        CustomViewRegistry.shared.unregisterAll()
        XCTAssertTrue(CustomViewRegistry.shared.registeredNames.isEmpty)
    }

    // MARK: - 6. IsRegistered -> true/false

    func testIsRegistered_returnsTrueForRegisteredFalseForNot() {
        CustomViewRegistry.shared.register(name: "Exists") { Text("Yes") }
        XCTAssertTrue(CustomViewRegistry.shared.isRegistered(name: "Exists"))
        XCTAssertFalse(CustomViewRegistry.shared.isRegistered(name: "DoesNotExist"))
    }

    // MARK: - 7. RegisteredNames -> lists all names

    func testRegisteredNames_listsAllNames() {
        CustomViewRegistry.shared.register(name: "Hero") { Text("Hero") }
        CustomViewRegistry.shared.register(name: "Pricing") { Text("Pricing") }

        let names = CustomViewRegistry.shared.registeredNames.sorted()
        XCTAssertEqual(names, ["Hero", "Pricing"])
    }

    // MARK: - 8. Re-register same name -> overwrites

    func testReRegister_overwritesPreviousBuilder() {
        var calledFirst = false
        var calledSecond = false

        CustomViewRegistry.shared.register(name: "Overwrite") {
            calledFirst = true
            return Text("First")
        }
        CustomViewRegistry.shared.register(name: "Overwrite") {
            calledSecond = true
            return Text("Second")
        }

        let context = makeContext(viewName: "Overwrite")
        _ = CustomViewRegistry.shared.resolve(name: "Overwrite", context: context)

        XCTAssertFalse(calledFirst, "First builder should not be called after overwrite")
        XCTAssertTrue(calledSecond, "Second builder should be called after overwrite")
    }

    // MARK: - 9. CustomViewContext has correct viewName

    func testContextViewName() {
        let context = CustomViewContext(viewName: "TestView")
        XCTAssertEqual(context.viewName, "TestView")
    }

    // MARK: - 10. CustomViewContext carries customData

    func testContextCustomData() {
        let customData: [String: AnyCodable] = [
            "title": AnyCodable("Hello"),
            "count": AnyCodable(42)
        ]
        let context = CustomViewContext(viewName: "Test", customData: customData)
        XCTAssertEqual(context.customData["title"]?.value as? String, "Hello")
        XCTAssertEqual(context.customData["count"]?.value as? Int, 42)
    }

    // MARK: - 11. CustomViewContext carries theme

    func testContextTheme() {
        let theme = PaywallTheme(primary: "#FF0000", accent: "#00FF00")
        let context = CustomViewContext(viewName: "Test", theme: theme)
        XCTAssertEqual(context.theme?.primary, "#FF0000")
        XCTAssertEqual(context.theme?.accent, "#00FF00")
    }

    // MARK: - 12. CustomViewContext carries products

    func testContextProducts() {
        let products = [
            ProductSlot(slot: "primary", label: "Monthly", productId: "monthly"),
            ProductSlot(slot: "secondary", label: "Yearly", productId: "yearly")
        ]
        let context = CustomViewContext(viewName: "Test", products: products)
        XCTAssertEqual(context.products?.count, 2)
        XCTAssertEqual(context.products?[0].slot, "primary")
        XCTAssertEqual(context.products?[1].label, "Yearly")
    }

    // MARK: - 13. Thread safety

    func testThreadSafety_concurrentRegistration() {
        let iterations = 100
        let expectation = XCTestExpectation(description: "Concurrent registration completes")
        expectation.expectedFulfillmentCount = iterations

        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)

        for i in 0..<iterations {
            queue.async {
                let name = "View\(i)"
                CustomViewRegistry.shared.register(name: name) {
                    Text(name)
                }
                _ = CustomViewRegistry.shared.isRegistered(name: name)
                _ = CustomViewRegistry.shared.registeredNames
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)

        // All views should be registered
        XCTAssertEqual(CustomViewRegistry.shared.registeredNames.count, iterations)
    }

    // MARK: - Helpers

    private func makeContext(viewName: String) -> CustomViewContext {
        CustomViewContext(viewName: viewName)
    }
}
