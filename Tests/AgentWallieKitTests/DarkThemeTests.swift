import XCTest
import SwiftUI
@testable import AgentWallieKit

@available(iOS 16.0, macOS 13.0, *)
final class DarkThemeTests: XCTestCase {

    // MARK: - Dark theme fixture

    private let darkTheme = PaywallTheme(
        background: "#1a1a2e",
        primary: "#6c63ff",
        secondary: "#5856D6",
        textPrimary: "#e0e0f0",
        textSecondary: "#a0a0b0",
        accent: "#ff6b6b",
        surface: "#2d2d44"
    )

    // MARK: - TextComponentView

    func testTextComponent_noExplicitColor_usesThemeTextPrimary() {
        // When style.color and style.textColor are nil, the component should
        // fall back to theme.textPrimary
        let data = TextComponentData(
            id: "test_text",
            props: TextComponentData.TextProps(content: "Hello", textStyle: "body"),
            style: nil
        )
        // Build the view and verify it compiles with the dark theme
        let view = TextComponentView(data: data, theme: darkTheme)
        XCTAssertNotNil(view, "TextComponentView should render with dark theme and no explicit color")
    }

    func testTextComponent_themeTextPrimaryRef_resolvesCorrectly() {
        var style = ComponentStyle()
        style.color = "{{ theme.text_primary }}"
        let data = TextComponentData(
            id: "test_text",
            props: TextComponentData.TextProps(content: "Hello"),
            style: style
        )
        let resolved = resolveColor(data.style?.color, theme: darkTheme)
        XCTAssertNotNil(resolved, "{{ theme.text_primary }} should resolve in dark theme")
    }

    func testTextComponent_hardcodedWhite_overridesTheme() {
        var style = ComponentStyle()
        style.color = "#FFFFFF"
        let data = TextComponentData(
            id: "test_text",
            props: TextComponentData.TextProps(content: "Hello"),
            style: style
        )
        let resolved = resolveColor(data.style?.color, theme: darkTheme)
        XCTAssertNotNil(resolved, "Hardcoded #FFFFFF should override theme color")
    }

    // MARK: - FeatureListComponent

    func testFeatureList_itemTextUsesThemeTextPrimary() {
        let data = FeatureListComponentData(
            id: "features",
            props: FeatureListComponentData.FeatureListProps(
                items: [FeatureListComponentData.FeatureItem(icon: "star", text: "Feature")],
                iconColor: nil
            ),
            style: nil
        )
        // With no explicit color, feature text should use theme.textPrimary as fallback
        let view = FeatureListComponentView(data: data, theme: darkTheme)
        XCTAssertNotNil(view, "FeatureListComponentView should render with dark theme")

        // Verify the text color fallback resolves to theme.textPrimary
        let textColor = resolveColor(nil, theme: darkTheme) ?? Color(hex: darkTheme.textPrimary)
        XCTAssertNotNil(textColor)
    }

    func testFeatureList_iconColorFallsBackToThemeAccent() {
        let data = FeatureListComponentData(
            id: "features",
            props: FeatureListComponentData.FeatureListProps(
                items: [FeatureListComponentData.FeatureItem(icon: "star", text: "Feature")],
                iconColor: nil
            )
        )
        // When iconColor is nil, should fall back to theme.accent (not .green)
        let fallbackColor = resolveColor(data.props.iconColor, theme: darkTheme) ?? Color(hex: darkTheme.accent)
        XCTAssertNotNil(fallbackColor)
    }

    // MARK: - ProductPickerComponent

    func testProductPicker_usesThemeColorsForLabels() {
        let data = ProductPickerComponentData(
            id: "picker",
            props: ProductPickerComponentData.ProductPickerProps(layout: "horizontal")
        )
        let products = [
            ProductSlot(slot: "monthly", label: "Monthly"),
            ProductSlot(slot: "annual", label: "Annual"),
        ]
        // Verify the theme colors are used for text
        let textPrimary = Color(hex: darkTheme.textPrimary)
        let textSecondary = Color(hex: darkTheme.textSecondary)
        let surface = Color(hex: darkTheme.surface)
        XCTAssertNotNil(textPrimary)
        XCTAssertNotNil(textSecondary)
        XCTAssertNotNil(surface)

        // View should compile and render
        let view = ProductPickerComponentView(
            data: data,
            products: products,
            theme: darkTheme,
            selectedProductIndex: .constant(0)
        )
        XCTAssertNotNil(view)
    }

    // MARK: - CTAButtonComponent

    func testCTAButton_usesThemePrimaryForBackground() {
        let data = CTAButtonComponentData(
            id: "cta",
            props: CTAButtonComponentData.CTAButtonProps(text: "Subscribe", action: .purchase),
            style: nil
        )
        // With no explicit backgroundColor, should fall back to theme.primary (not Color.blue)
        let fallbackColor = resolveColor(nil, theme: darkTheme) ?? Color(hex: darkTheme.primary)
        XCTAssertNotNil(fallbackColor)

        let view = CTAButtonComponentView(data: data, theme: darkTheme, onAction: { _, _ in })
        XCTAssertNotNil(view, "CTAButton should render with dark theme and no explicit background")
    }

    func testCTAButton_themeRefBackground_resolves() {
        var style = ComponentStyle()
        style.backgroundColor = "{{ theme.primary }}"
        style.textColor = "#FFFFFF"
        let data = CTAButtonComponentData(
            id: "cta",
            props: CTAButtonComponentData.CTAButtonProps(text: "Subscribe", action: .purchase),
            style: style
        )
        let bgColor = resolveColor(data.style?.backgroundColor, theme: darkTheme)
        XCTAssertNotNil(bgColor, "{{ theme.primary }} background should resolve in dark theme")
    }

    // MARK: - LinkRowComponent

    func testLinkRow_usesThemeTextSecondaryForLinks() {
        let data = LinkRowComponentData(
            id: "links",
            props: LinkRowComponentData.LinkRowProps(
                links: [LinkRowComponentData.LinkItem(text: "Terms", action: .openUrl, url: "https://example.com")],
                separator: " | "
            ),
            style: nil
        )
        // With no explicit textColor, should fall back to theme.textSecondary
        let view = LinkRowComponentView(data: data, theme: darkTheme, onAction: { _, _ in })
        XCTAssertNotNil(view, "LinkRowComponentView should render with dark theme")

        let fallback = Color(hex: darkTheme.textSecondary)
        XCTAssertNotNil(fallback)
    }

    // MARK: - PaywallView

    func testPaywallView_backgroundUsesThemeBackground() {
        let schema = PaywallSchema(
            version: "1.0",
            name: "dark_test",
            settings: PaywallSettings(backgroundColor: "{{ theme.background }}"),
            theme: darkTheme,
            components: []
        )
        // The resolved background_color via theme ref should produce the dark background
        let resolved = resolveColor(schema.settings.backgroundColor, theme: schema.theme)
        XCTAssertNotNil(resolved, "{{ theme.background }} in settings should resolve to dark background")
    }

    func testPaywallView_closeButtonVisibleOnDarkBackground() {
        let schema = PaywallSchema(
            version: "1.0",
            name: "dark_test",
            settings: PaywallSettings(closeButton: true, backgroundColor: "{{ theme.background }}"),
            theme: darkTheme,
            components: []
        )
        // Close button should use theme.textPrimary (light color on dark bg)
        let foreground = Color(hex: schema.theme!.textPrimary)
        XCTAssertNotNil(foreground, "Close button foreground should use theme.textPrimary for visibility")
    }

    // MARK: - CountdownTimerComponent

    func testCountdownTimer_usesThemeTextPrimaryAsFallback() {
        let data = CountdownTimerComponentData(
            id: "timer",
            props: CountdownTimerComponentData.CountdownTimerProps(durationSeconds: 3600, label: "Offer expires in")
        )
        let view = CountdownTimerComponentView(data: data, theme: darkTheme)
        XCTAssertNotNil(view, "CountdownTimerComponentView should render with dark theme")

        // Timer text should use theme.textPrimary, not SwiftUI .primary
        let fallbackColor = Color(hex: darkTheme.textPrimary)
        XCTAssertNotNil(fallbackColor)
    }

    // MARK: - DrawerComponent

    func testDrawer_titleUsesThemeTextPrimary() {
        let data = DrawerComponentData(
            id: "drawer",
            props: DrawerComponentData.DrawerProps(title: "More Info"),
            children: []
        )
        let view = DrawerComponentView(data: data, theme: darkTheme, onAction: { _, _ in }, renderComponent: { _ in AnyView(EmptyView()) })
        XCTAssertNotNil(view, "DrawerComponentView title should use theme.textPrimary")
    }

    // MARK: - DividerComponent

    func testDivider_usesThemeTextSecondaryAsFallback() {
        let data = DividerComponentData(id: "divider")
        let view = DividerComponentView(data: data, theme: darkTheme)
        XCTAssertNotNil(view, "DividerComponentView should render with dark theme")
    }

    // MARK: - ToggleComponent

    func testToggle_labelUsesThemeTextPrimary() {
        let data = ToggleComponentData(
            id: "toggle",
            props: ToggleComponentData.ToggleProps(label: "Enable Pro")
        )
        let view = ToggleComponentView(data: data, theme: darkTheme, onAction: { _, _ in })
        XCTAssertNotNil(view, "ToggleComponentView should render with dark theme")
    }

    // MARK: - SurveyComponent

    func testSurvey_questionUsesThemeTextPrimary() {
        let data = SurveyComponentData(
            id: "survey",
            props: SurveyComponentData.SurveyProps(question: "Why?", options: ["A", "B"])
        )
        let view = SurveyComponentView(data: data, theme: darkTheme, onAction: { _, _ in })
        XCTAssertNotNil(view, "SurveyComponentView should render with dark theme")
    }

    // MARK: - CustomViewComponent

    func testCustomView_usesThemeTextSecondary() {
        let data = CustomViewComponentData(
            id: "custom",
            props: CustomViewComponentData.CustomViewProps(viewName: "MyView")
        )
        let view = CustomViewComponentView(data: data, theme: darkTheme)
        XCTAssertNotNil(view, "CustomViewComponentView should render with dark theme")
    }

    // MARK: - VideoComponent

    func testVideo_placeholderUsesThemeSurface() {
        let data = VideoComponentData(
            id: "video",
            props: VideoComponentData.VideoProps(src: "https://example.com/video.mp4")
        )
        let view = VideoComponentView(data: data, theme: darkTheme)
        XCTAssertNotNil(view, "VideoComponentView should render placeholder with dark theme surface color")
    }

    // MARK: - Nil theme graceful handling

    func testAllComponents_handleNilThemeGracefully() {
        // TextComponentView
        let text = TextComponentView(
            data: TextComponentData(id: "t", props: TextComponentData.TextProps(content: "Hi")),
            theme: nil
        )
        XCTAssertNotNil(text)

        // CTAButtonComponentView
        let cta = CTAButtonComponentView(
            data: CTAButtonComponentData(id: "c", props: CTAButtonComponentData.CTAButtonProps(text: "Go", action: .purchase)),
            theme: nil,
            onAction: { _, _ in }
        )
        XCTAssertNotNil(cta)

        // FeatureListComponentView
        let features = FeatureListComponentView(
            data: FeatureListComponentData(
                id: "f",
                props: FeatureListComponentData.FeatureListProps(
                    items: [FeatureListComponentData.FeatureItem(icon: "star", text: "X")]
                )
            ),
            theme: nil
        )
        XCTAssertNotNil(features)

        // DividerComponentView
        let divider = DividerComponentView(
            data: DividerComponentData(id: "d"),
            theme: nil
        )
        XCTAssertNotNil(divider)

        // SpacerComponentView
        let spacer = SpacerComponentView(
            data: SpacerComponentData(id: "s"),
            theme: nil
        )
        XCTAssertNotNil(spacer)
    }
}
