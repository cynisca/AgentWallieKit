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

    func testSDKConfigWithProducts() throws {
        let json = """
        {
            "campaigns": [],
            "paywalls": {},
            "products": [
                {
                    "id": "prod_1",
                    "name": "Premium Monthly",
                    "store": "apple",
                    "store_product_id": "com.app.premium.monthly",
                    "entitlements": ["premium"],
                    "display_price": "$9.99",
                    "display_period": "month"
                },
                {
                    "id": "prod_2",
                    "name": "Premium Yearly",
                    "store": "apple",
                    "store_product_id": "com.app.premium.yearly",
                    "entitlements": ["premium"],
                    "display_price": "$79.99",
                    "display_period": "year"
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(SDKConfig.self, from: data)

        XCTAssertEqual(config.products.count, 2)
        XCTAssertEqual(config.products[0].id, "prod_1")
        XCTAssertEqual(config.products[0].name, "Premium Monthly")
        XCTAssertEqual(config.products[0].store, .apple)
        XCTAssertEqual(config.products[0].storeProductId, "com.app.premium.monthly")
        XCTAssertEqual(config.products[0].entitlements, ["premium"])
        XCTAssertEqual(config.products[0].displayPrice, "$9.99")
        XCTAssertEqual(config.products[1].storeProductId, "com.app.premium.yearly")
    }

    func testSDKConfigWithoutProductsField() throws {
        let json = """
        {
            "campaigns": [],
            "paywalls": {}
        }
        """

        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(SDKConfig.self, from: data)

        XCTAssertEqual(config.products.count, 0, "products should default to empty array")
    }

    func testSDKConfigRoundTripWithProducts() throws {
        let product = AWProduct(
            id: "prod_1",
            name: "Premium",
            store: .apple,
            storeProductId: "com.app.premium",
            entitlements: ["premium", "no_ads"]
        )

        let config = SDKConfig(campaigns: [], paywalls: [:], products: [product])

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(SDKConfig.self, from: data)

        XCTAssertEqual(decoded.products.count, 1)
        XCTAssertEqual(decoded.products[0].id, "prod_1")
        XCTAssertEqual(decoded.products[0].storeProductId, "com.app.premium")
        XCTAssertEqual(decoded.products[0].entitlements, ["premium", "no_ads"])
    }

    func testProductSlotWithProductId() throws {
        let json = """
        {
            "slot": "primary",
            "label": "Yearly",
            "product_id": "prod_1"
        }
        """

        let data = json.data(using: .utf8)!
        let slot = try JSONDecoder().decode(ProductSlot.self, from: data)

        XCTAssertEqual(slot.slot, "primary")
        XCTAssertEqual(slot.label, "Yearly")
        XCTAssertEqual(slot.productId, "prod_1")
    }

    func testSpacerComponentDecoding() throws {
        let json = """
        {
            "type": "spacer",
            "id": "spacer1",
            "style": { "height": 24 }
        }
        """

        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(PaywallComponent.self, from: data)

        if case .spacer(let spacerData) = component {
            XCTAssertEqual(spacerData.id, "spacer1")
            XCTAssertEqual(spacerData.style?.height?.doubleValue, 24)
        } else {
            XCTFail("Expected spacer component")
        }
    }

    func testDividerComponentDecoding() throws {
        let json = """
        {
            "type": "divider",
            "id": "div1",
            "props": { "color": "#CCCCCC", "thickness": 2.0 }
        }
        """

        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(PaywallComponent.self, from: data)

        if case .divider(let divData) = component {
            XCTAssertEqual(divData.id, "div1")
            XCTAssertEqual(divData.props?.color, "#CCCCCC")
            XCTAssertEqual(divData.props?.thickness, 2.0)
        } else {
            XCTFail("Expected divider component")
        }
    }

    func testStackComponentDecoding() throws {
        let json = """
        {
            "type": "stack",
            "id": "stack1",
            "props": { "direction": "horizontal", "spacing": 8 },
            "children": [
                {
                    "type": "text",
                    "id": "t1",
                    "props": { "content": "Hello" }
                },
                {
                    "type": "text",
                    "id": "t2",
                    "props": { "content": "World" }
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(PaywallComponent.self, from: data)

        if case .stack(let stackData) = component {
            XCTAssertEqual(stackData.id, "stack1")
            XCTAssertEqual(stackData.props.direction, "horizontal")
            XCTAssertEqual(stackData.props.spacing, 8)
            XCTAssertEqual(stackData.children.count, 2)
        } else {
            XCTFail("Expected stack component")
        }
    }

    func testCountdownTimerComponentDecoding() throws {
        let json = """
        {
            "type": "countdown_timer",
            "id": "timer1",
            "props": { "duration_seconds": 3600, "label": "Offer ends in" }
        }
        """

        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(PaywallComponent.self, from: data)

        if case .countdownTimer(let timerData) = component {
            XCTAssertEqual(timerData.id, "timer1")
            XCTAssertEqual(timerData.props.durationSeconds, 3600)
            XCTAssertEqual(timerData.props.label, "Offer ends in")
        } else {
            XCTFail("Expected countdown_timer component")
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
