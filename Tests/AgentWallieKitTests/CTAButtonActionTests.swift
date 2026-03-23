import XCTest
@testable import AgentWallieKit

final class CTAButtonActionTests: XCTestCase {

    // MARK: - resolveActionParam tests

    func testPurchaseAction_passesProductSlot() {
        let props = CTAButtonComponentData.CTAButtonProps(
            text: "Subscribe",
            action: .purchase,
            product: "selected"
        )
        XCTAssertEqual(resolveActionParam(for: props), "selected")
    }

    func testSelectProductAction_passesProductSlot() {
        let props = CTAButtonComponentData.CTAButtonProps(
            text: "Choose Plan",
            action: .selectProduct,
            product: "primary"
        )
        XCTAssertEqual(resolveActionParam(for: props), "primary")
    }

    func testPurchaseAction_withNoProduct_defaultsToSelected() {
        let props = CTAButtonComponentData.CTAButtonProps(
            text: "REVEAL MY VERDICT — 3 DAYS FREE",
            action: .purchase
        )
        XCTAssertEqual(resolveActionParam(for: props), "selected",
            "purchase with no product should default to 'selected'")
    }

    func testCustomAction_passesActionName() {
        let props = CTAButtonComponentData.CTAButtonProps(
            text: "Invite 2 friends to unlock for free",
            action: .customAction,
            actionName: "open_invite"
        )
        XCTAssertEqual(resolveActionParam(for: props), "open_invite")
    }

    func testCustomAction_withNoActionName_returnsNil() {
        let props = CTAButtonComponentData.CTAButtonProps(
            text: "Do Something",
            action: .customAction
        )
        XCTAssertNil(resolveActionParam(for: props))
    }

    func testCustomPlacement_passesPlacementName() {
        let props = CTAButtonComponentData.CTAButtonProps(
            text: "Show Upgrade",
            action: .customPlacement,
            placementName: "upgrade_flow"
        )
        XCTAssertEqual(resolveActionParam(for: props), "upgrade_flow")
    }

    func testOpenUrl_passesUrl() {
        let props = CTAButtonComponentData.CTAButtonProps(
            text: "Terms of Service",
            action: .openUrl,
            url: "https://example.com/terms"
        )
        XCTAssertEqual(resolveActionParam(for: props), "https://example.com/terms")
    }

    func testCloseAction_returnsNil() {
        let props = CTAButtonComponentData.CTAButtonProps(
            text: "Close",
            action: .close
        )
        XCTAssertNil(resolveActionParam(for: props))
    }

    func testRestoreAction_returnsNil() {
        let props = CTAButtonComponentData.CTAButtonProps(
            text: "Restore",
            action: .restore
        )
        XCTAssertNil(resolveActionParam(for: props))
    }

    // MARK: - Bug regression: custom_action must NOT pass product

    func testCustomAction_doesNotPassProduct() {
        // This is the bug: a custom_action button with a product field set
        // should still pass actionName, not product
        let props = CTAButtonComponentData.CTAButtonProps(
            text: "Invite Friends",
            action: .customAction,
            product: "primary",
            actionName: "open_invite"
        )
        let param = resolveActionParam(for: props)
        XCTAssertEqual(param, "open_invite", "custom_action should pass actionName, not product")
        XCTAssertNotEqual(param, "primary", "custom_action must not pass product slot")
    }

    // MARK: - CTA button view onAction wiring

    func testResolveActionParam_withPaddingVerticalStyle() {
        // Reproduces CutOrBulk's CTA style: padding_vertical but no height
        let props = CTAButtonComponentData.CTAButtonProps(
            text: "REVEAL MY VERDICT — 3 DAYS FREE",
            action: .purchase
        )
        let param = resolveActionParam(for: props)
        XCTAssertEqual(param, "selected",
            "purchase with no product should default to 'selected' regardless of styling")
    }

    func testCTAButtonView_usesResolveActionParam() {
        // Regression: the view previously passed data.props.product for ALL
        // action types, so custom_action buttons with actionName but no product
        // would pass nil — handleCustomAction was never called.
        let data = CTAButtonComponentData(
            id: "invite",
            props: CTAButtonComponentData.CTAButtonProps(
                text: "Invite Friends",
                action: .customAction,
                actionName: "open_invite"
            )
        )

        // product is nil for custom_action buttons
        XCTAssertNil(data.props.product)

        // resolveActionParam correctly returns actionName
        let param = resolveActionParam(for: data.props)
        XCTAssertEqual(param, "open_invite")
    }
}
