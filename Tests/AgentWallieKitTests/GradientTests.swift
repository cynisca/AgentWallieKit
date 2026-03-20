import XCTest
@testable import AgentWallieKit

@available(iOS 16.0, *)
final class GradientTests: XCTestCase {

    // MARK: - Direction Mapping

    func testVerticalGradientPoints() {
        let gradient = BackgroundGradient(colors: ["#FF0000", "#0000FF"], direction: "vertical")
        let view = GradientBackground(gradient: gradient, theme: nil)
        XCTAssertEqual(view.startPoint, .top)
        XCTAssertEqual(view.endPoint, .bottom)
    }

    func testHorizontalGradientPoints() {
        let gradient = BackgroundGradient(colors: ["#FF0000", "#0000FF"], direction: "horizontal")
        let view = GradientBackground(gradient: gradient, theme: nil)
        XCTAssertEqual(view.startPoint, .leading)
        XCTAssertEqual(view.endPoint, .trailing)
    }

    func testDiagonalDownGradientPoints() {
        let gradient = BackgroundGradient(colors: ["#FF0000", "#0000FF"], direction: "diagonal_down")
        let view = GradientBackground(gradient: gradient, theme: nil)
        XCTAssertEqual(view.startPoint, .topLeading)
        XCTAssertEqual(view.endPoint, .bottomTrailing)
    }

    func testDiagonalUpGradientPoints() {
        let gradient = BackgroundGradient(colors: ["#FF0000", "#0000FF"], direction: "diagonal_up")
        let view = GradientBackground(gradient: gradient, theme: nil)
        XCTAssertEqual(view.startPoint, .bottomLeading)
        XCTAssertEqual(view.endPoint, .topTrailing)
    }

    func testDefaultDirectionIsVertical() {
        let gradient = BackgroundGradient(colors: ["#FF0000", "#0000FF"], direction: nil)
        let view = GradientBackground(gradient: gradient, theme: nil)
        XCTAssertEqual(view.startPoint, .top)
        XCTAssertEqual(view.endPoint, .bottom)
    }

    // MARK: - Color Resolution

    func testHexColorsResolve() {
        let gradient = BackgroundGradient(colors: ["#FF0000", "#00FF00", "#0000FF"], direction: "vertical")
        let view = GradientBackground(gradient: gradient, theme: nil)
        XCTAssertEqual(view.resolvedColors.count, 3)
    }

    func testThemeColorReferencesResolve() {
        let theme = PaywallTheme(primary: "#007AFF", secondary: "#5856D6")
        let gradient = BackgroundGradient(
            colors: ["{{ theme.primary }}", "{{ theme.secondary }}"],
            direction: "vertical"
        )
        let view = GradientBackground(gradient: gradient, theme: theme)
        XCTAssertEqual(view.resolvedColors.count, 2)
    }

    func testMixedHexAndThemeColors() {
        let theme = PaywallTheme(primary: "#007AFF")
        let gradient = BackgroundGradient(
            colors: ["{{ theme.primary }}", "#FF0000"],
            direction: "horizontal"
        )
        let view = GradientBackground(gradient: gradient, theme: theme)
        XCTAssertEqual(view.resolvedColors.count, 2)
    }

    // MARK: - Edge Cases

    func testEmptyColorsArrayHandledGracefully() {
        let gradient = BackgroundGradient(colors: [], direction: "vertical")
        let view = GradientBackground(gradient: gradient, theme: nil)
        XCTAssertTrue(view.resolvedColors.isEmpty)
    }

    func testSingleColorGradient() {
        let gradient = BackgroundGradient(colors: ["#FF0000"], direction: "vertical")
        let view = GradientBackground(gradient: gradient, theme: nil)
        XCTAssertEqual(view.resolvedColors.count, 1)
    }

    func testInvalidThemeRefWithoutTheme() {
        let gradient = BackgroundGradient(
            colors: ["{{ theme.primary }}"],
            direction: "vertical"
        )
        let view = GradientBackground(gradient: gradient, theme: nil)
        // Theme ref without a theme should not resolve
        XCTAssertTrue(view.resolvedColors.isEmpty)
    }
}
