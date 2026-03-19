import XCTest
@testable import AgentWallieKit

final class ConfigModelTests: XCTestCase {

    func testPaywallSchemaDecoding() throws {
        let json = """
        {
            "version": "1.0",
            "name": "test_paywall",
            "settings": {
                "presentation": "modal",
                "close_button": true,
                "close_button_delay_ms": 0,
                "background_color": "#FFFFFF",
                "scroll_enabled": true,
                "safe_area_insets": true
            },
            "theme": {
                "background": "#FFFFFF",
                "primary": "#007AFF",
                "secondary": "#5856D6",
                "text_primary": "#000000",
                "text_secondary": "#6B7280",
                "accent": "#34C759",
                "surface": "#F2F2F7",
                "corner_radius": 12,
                "font_family": "system"
            },
            "products": [
                { "slot": "primary", "label": "Yearly" },
                { "slot": "secondary", "label": "Monthly" }
            ],
            "components": [
                {
                    "type": "text",
                    "id": "title",
                    "props": {
                        "content": "Unlock Everything",
                        "text_style": "title1",
                        "alignment": "center"
                    },
                    "style": {
                        "color": "#000000",
                        "margin_bottom": 8
                    }
                },
                {
                    "type": "cta_button",
                    "id": "buy",
                    "props": {
                        "text": "Subscribe Now",
                        "action": "purchase",
                        "product": "primary"
                    },
                    "style": {
                        "background_color": "#007AFF",
                        "text_color": "#FFFFFF",
                        "corner_radius": 12,
                        "height": 56
                    }
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let schema = try JSONDecoder().decode(PaywallSchema.self, from: data)

        XCTAssertEqual(schema.version, "1.0")
        XCTAssertEqual(schema.name, "test_paywall")
        XCTAssertEqual(schema.settings.presentation, .modal)
        XCTAssertTrue(schema.settings.closeButton)
        XCTAssertEqual(schema.settings.backgroundColor, "#FFFFFF")

        XCTAssertEqual(schema.theme?.primary, "#007AFF")
        XCTAssertEqual(schema.theme?.cornerRadius, 12)

        XCTAssertEqual(schema.products?.count, 2)
        XCTAssertEqual(schema.products?[0].slot, "primary")

        XCTAssertEqual(schema.components.count, 2)

        // Verify text component
        if case .text(let textData) = schema.components[0] {
            XCTAssertEqual(textData.props.content, "Unlock Everything")
            XCTAssertEqual(textData.props.textStyle, "title1")
        } else {
            XCTFail("Expected text component")
        }

        // Verify CTA button component
        if case .ctaButton(let ctaData) = schema.components[1] {
            XCTAssertEqual(ctaData.props.text, "Subscribe Now")
            XCTAssertEqual(ctaData.props.action, .purchase)
            XCTAssertEqual(ctaData.props.product, "primary")
        } else {
            XCTFail("Expected cta_button component")
        }
    }

    func testPaywallSchemaRoundTrip() throws {
        let schema = PaywallSchema(
            version: "1.0",
            name: "roundtrip_test",
            settings: PaywallSettings(
                presentation: .fullscreen,
                closeButton: false,
                closeButtonDelayMs: 1000,
                backgroundColor: "#000000",
                scrollEnabled: true,
                safeAreaInsets: false
            ),
            theme: PaywallTheme(
                background: "#000000",
                primary: "#FF0000",
                secondary: "#00FF00",
                textPrimary: "#FFFFFF",
                textSecondary: "#CCCCCC",
                accent: "#0000FF",
                surface: "#111111",
                cornerRadius: 8,
                fontFamily: "system"
            ),
            products: [
                ProductSlot(slot: "primary", label: "Annual")
            ],
            components: [
                .text(TextComponentData(
                    id: "title",
                    props: TextComponentData.TextProps(content: "Hello", textStyle: "title1", alignment: "center")
                ))
            ]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(schema)
        let decoded = try JSONDecoder().decode(PaywallSchema.self, from: data)

        XCTAssertEqual(decoded.version, "1.0")
        XCTAssertEqual(decoded.name, "roundtrip_test")
        XCTAssertEqual(decoded.settings.presentation, .fullscreen)
        XCTAssertFalse(decoded.settings.closeButton)
        XCTAssertEqual(decoded.theme?.primary, "#FF0000")
        XCTAssertEqual(decoded.products?.count, 1)
        XCTAssertEqual(decoded.components.count, 1)
    }

    func testCampaignDecoding() throws {
        let json = """
        {
            "id": "c1",
            "name": "Test Campaign",
            "status": "active",
            "placements": [
                {"id": "p1", "name": "onboarding", "type": "custom", "status": "active"}
            ],
            "audiences": [
                {
                    "id": "a1",
                    "name": "Free Users",
                    "priority_order": 0,
                    "filters": [
                        {"field": "user.plan", "operator": "is", "value": "free"}
                    ],
                    "experiment": {
                        "id": "e1",
                        "variants": [
                            {"id": "v1", "paywall_id": "pw1", "traffic_percentage": 50},
                            {"id": "v2", "paywall_id": "pw2", "traffic_percentage": 50}
                        ],
                        "holdout_percentage": 0,
                        "status": "running"
                    }
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let campaign = try JSONDecoder().decode(Campaign.self, from: data)

        XCTAssertEqual(campaign.id, "c1")
        XCTAssertEqual(campaign.status, .active)
        XCTAssertEqual(campaign.placements.count, 1)
        XCTAssertEqual(campaign.audiences.count, 1)

        let audience = campaign.audiences[0]
        XCTAssertEqual(audience.filters.count, 1)
        XCTAssertEqual(audience.filters[0].field, "user.plan")
        XCTAssertEqual(audience.filters[0].operator, .is)

        let experiment = audience.experiment!
        XCTAssertEqual(experiment.variants.count, 2)
        XCTAssertEqual(experiment.holdoutPercentage, 0)
    }

    func testFeatureListComponentDecoding() throws {
        let json = """
        {
            "type": "feature_list",
            "id": "features",
            "props": {
                "items": [
                    {"icon": "checkmark.circle.fill", "text": "Unlimited access"},
                    {"icon": "checkmark.circle.fill", "text": "No ads"}
                ],
                "icon_color": "#34C759"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(PaywallComponent.self, from: data)

        if case .featureList(let featureData) = component {
            XCTAssertEqual(featureData.props.items.count, 2)
            XCTAssertEqual(featureData.props.items[0].text, "Unlimited access")
            XCTAssertEqual(featureData.props.iconColor, "#34C759")
        } else {
            XCTFail("Expected feature_list component")
        }
    }

    func testUnknownComponentType() throws {
        let json = """
        {
            "type": "some_future_component",
            "id": "future",
            "props": {}
        }
        """

        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(PaywallComponent.self, from: data)

        if case .unknown(let type) = component {
            XCTAssertEqual(type, "some_future_component")
        } else {
            XCTFail("Expected unknown component")
        }
    }
}
