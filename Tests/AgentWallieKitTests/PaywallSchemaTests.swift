import XCTest
@testable import AgentWallieKit

final class PaywallSchemaTests: XCTestCase {

    // MARK: - Helper

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func decodeComponent(_ json: String) throws -> PaywallComponent {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(PaywallComponent.self, from: data)
    }

    // MARK: - TextComponentData

    func testTextComponentRoundTrip() throws {
        let component = PaywallComponent.text(TextComponentData(
            id: "t1",
            props: TextComponentData.TextProps(content: "Hello World", textStyle: "title1", alignment: "center")
        ))
        let decoded = try roundTrip(component)
        if case .text(let d) = decoded {
            XCTAssertEqual(d.id, "t1")
            XCTAssertEqual(d.props.content, "Hello World")
            XCTAssertEqual(d.props.textStyle, "title1")
            XCTAssertEqual(d.props.alignment, "center")
        } else {
            XCTFail("Expected text component")
        }
    }

    // MARK: - ImageComponentData

    func testImageComponentRoundTrip() throws {
        let component = PaywallComponent.image(ImageComponentData(
            id: "img1",
            props: ImageComponentData.ImageProps(src: "https://example.com/hero.png", alt: "Hero image", aspectRatio: "16:9", fit: "cover")
        ))
        let decoded = try roundTrip(component)
        if case .image(let d) = decoded {
            XCTAssertEqual(d.id, "img1")
            XCTAssertEqual(d.props.src, "https://example.com/hero.png")
            XCTAssertEqual(d.props.alt, "Hero image")
            XCTAssertEqual(d.props.aspectRatio, "16:9")
            XCTAssertEqual(d.props.fit, "cover")
        } else {
            XCTFail("Expected image component")
        }
    }

    // MARK: - CTAButtonComponentData

    func testCTAButtonComponentRoundTrip() throws {
        let component = PaywallComponent.ctaButton(CTAButtonComponentData(
            id: "cta1",
            props: CTAButtonComponentData.CTAButtonProps(
                text: "Buy Now",
                subtitle: "Best deal",
                action: .purchase,
                product: "primary",
                url: nil,
                actionName: nil,
                placementName: nil
            )
        ))
        let decoded = try roundTrip(component)
        if case .ctaButton(let d) = decoded {
            XCTAssertEqual(d.id, "cta1")
            XCTAssertEqual(d.props.text, "Buy Now")
            XCTAssertEqual(d.props.subtitle, "Best deal")
            XCTAssertEqual(d.props.action, .purchase)
            XCTAssertEqual(d.props.product, "primary")
        } else {
            XCTFail("Expected cta_button component")
        }
    }

    // MARK: - ProductPickerComponentData

    func testProductPickerComponentRoundTrip() throws {
        let component = PaywallComponent.productPicker(ProductPickerComponentData(
            id: "picker1",
            props: ProductPickerComponentData.ProductPickerProps(
                layout: "vertical",
                showSavingsBadge: true,
                savingsText: "Save 50%",
                selectedBorderColor: "#FF0000"
            )
        ))
        let decoded = try roundTrip(component)
        if case .productPicker(let d) = decoded {
            XCTAssertEqual(d.id, "picker1")
            XCTAssertEqual(d.props.layout, "vertical")
            XCTAssertEqual(d.props.showSavingsBadge, true)
            XCTAssertEqual(d.props.savingsText, "Save 50%")
            XCTAssertEqual(d.props.selectedBorderColor, "#FF0000")
        } else {
            XCTFail("Expected product_picker component")
        }
    }

    // MARK: - FeatureListComponentData

    func testFeatureListComponentRoundTrip() throws {
        let component = PaywallComponent.featureList(FeatureListComponentData(
            id: "fl1",
            props: FeatureListComponentData.FeatureListProps(
                items: [
                    FeatureListComponentData.FeatureItem(icon: "checkmark", text: "Feature A"),
                    FeatureListComponentData.FeatureItem(icon: "star", text: "Feature B"),
                ],
                iconColor: "#00FF00"
            )
        ))
        let decoded = try roundTrip(component)
        if case .featureList(let d) = decoded {
            XCTAssertEqual(d.id, "fl1")
            XCTAssertEqual(d.props.items.count, 2)
            XCTAssertEqual(d.props.items[0].icon, "checkmark")
            XCTAssertEqual(d.props.items[0].text, "Feature A")
            XCTAssertEqual(d.props.items[1].text, "Feature B")
            XCTAssertEqual(d.props.iconColor, "#00FF00")
        } else {
            XCTFail("Expected feature_list component")
        }
    }

    // MARK: - LinkRowComponentData

    func testLinkRowComponentRoundTrip() throws {
        let component = PaywallComponent.linkRow(LinkRowComponentData(
            id: "lr1",
            props: LinkRowComponentData.LinkRowProps(
                links: [
                    LinkRowComponentData.LinkItem(text: "Terms", action: .openUrl, url: "https://example.com/terms"),
                    LinkRowComponentData.LinkItem(text: "Restore", action: .restore),
                ],
                separator: " | "
            )
        ))
        let decoded = try roundTrip(component)
        if case .linkRow(let d) = decoded {
            XCTAssertEqual(d.id, "lr1")
            XCTAssertEqual(d.props.links.count, 2)
            XCTAssertEqual(d.props.links[0].text, "Terms")
            XCTAssertEqual(d.props.links[0].action, .openUrl)
            XCTAssertEqual(d.props.links[0].url, "https://example.com/terms")
            XCTAssertEqual(d.props.links[1].text, "Restore")
            XCTAssertEqual(d.props.links[1].action, .restore)
            XCTAssertEqual(d.props.separator, " | ")
        } else {
            XCTFail("Expected link_row component")
        }
    }

    // MARK: - SpacerComponentData

    func testSpacerComponentRoundTrip() throws {
        var style = ComponentStyle()
        style.height = .number(32)
        let component = PaywallComponent.spacer(SpacerComponentData(id: "sp1", style: style))
        let decoded = try roundTrip(component)
        if case .spacer(let d) = decoded {
            XCTAssertEqual(d.id, "sp1")
            XCTAssertEqual(d.style?.height?.doubleValue, 32)
        } else {
            XCTFail("Expected spacer component")
        }
    }

    // MARK: - DividerComponentData

    func testDividerComponentRoundTrip() throws {
        let component = PaywallComponent.divider(DividerComponentData(
            id: "div1",
            props: DividerComponentData.DividerProps(color: "#AAAAAA", thickness: 1.5)
        ))
        let decoded = try roundTrip(component)
        if case .divider(let d) = decoded {
            XCTAssertEqual(d.id, "div1")
            XCTAssertEqual(d.props?.color, "#AAAAAA")
            XCTAssertEqual(d.props?.thickness, 1.5)
        } else {
            XCTFail("Expected divider component")
        }
    }

    // MARK: - StackComponentData with children

    func testStackComponentWithChildrenRoundTrip() throws {
        let component = PaywallComponent.stack(StackComponentData(
            id: "stack1",
            props: StackComponentData.StackProps(direction: "horizontal", spacing: 12, alignment: "center"),
            children: [
                .text(TextComponentData(id: "c1", props: TextComponentData.TextProps(content: "Left"))),
                .text(TextComponentData(id: "c2", props: TextComponentData.TextProps(content: "Right"))),
            ]
        ))
        let decoded = try roundTrip(component)
        if case .stack(let d) = decoded {
            XCTAssertEqual(d.id, "stack1")
            XCTAssertEqual(d.props.direction, "horizontal")
            XCTAssertEqual(d.props.spacing, 12)
            XCTAssertEqual(d.props.alignment, "center")
            XCTAssertEqual(d.children.count, 2)
        } else {
            XCTFail("Expected stack component")
        }
    }

    func testStackComponentDecodesWithoutChildren() throws {
        let json = """
        {"type":"stack","id":"s1","props":{"direction":"horizontal"}}
        """.data(using: .utf8)!
        let component = try JSONDecoder().decode(PaywallComponent.self, from: json)
        if case .stack(let d) = component {
            XCTAssertEqual(d.children.count, 0)
        } else {
            XCTFail("Expected stack")
        }
    }

    func testCarouselDecodesWithoutChildren() throws {
        let json = """
        {"type":"carousel","id":"c1","props":{"auto_scroll":false,"interval_ms":3000}}
        """.data(using: .utf8)!
        let component = try JSONDecoder().decode(PaywallComponent.self, from: json)
        if case .carousel(let d) = component {
            XCTAssertEqual(d.children.count, 0)
        } else {
            XCTFail("Expected carousel")
        }
    }

    func testDrawerDecodesWithoutChildren() throws {
        let json = """
        {"type":"drawer","id":"d1","props":{"title":"Info","expanded":true}}
        """.data(using: .utf8)!
        let component = try JSONDecoder().decode(PaywallComponent.self, from: json)
        if case .drawer(let d) = component {
            XCTAssertEqual(d.children.count, 0)
        } else {
            XCTFail("Expected drawer")
        }
    }

    // MARK: - CountdownTimerComponentData

    func testCountdownTimerComponentRoundTrip() throws {
        let component = PaywallComponent.countdownTimer(CountdownTimerComponentData(
            id: "timer1",
            props: CountdownTimerComponentData.CountdownTimerProps(durationSeconds: 1800, label: "Hurry!")
        ))
        let decoded = try roundTrip(component)
        if case .countdownTimer(let d) = decoded {
            XCTAssertEqual(d.id, "timer1")
            XCTAssertEqual(d.props.durationSeconds, 1800)
            XCTAssertEqual(d.props.label, "Hurry!")
        } else {
            XCTFail("Expected countdown_timer component")
        }
    }

    // MARK: - VideoComponentData

    func testVideoComponentRoundTrip() throws {
        let component = PaywallComponent.video(VideoComponentData(
            id: "vid1",
            props: VideoComponentData.VideoProps(src: "https://example.com/video.mp4", autoplay: true, loop: true, muted: true, poster: "https://example.com/poster.jpg")
        ))
        let decoded = try roundTrip(component)
        if case .video(let d) = decoded {
            XCTAssertEqual(d.id, "vid1")
            XCTAssertEqual(d.props.src, "https://example.com/video.mp4")
            XCTAssertTrue(d.props.autoplay)
            XCTAssertTrue(d.props.loop)
            XCTAssertTrue(d.props.muted)
            XCTAssertEqual(d.props.poster, "https://example.com/poster.jpg")
        } else {
            XCTFail("Expected video component")
        }
    }

    // MARK: - DrawerComponentData with children

    func testDrawerComponentWithChildrenRoundTrip() throws {
        let component = PaywallComponent.drawer(DrawerComponentData(
            id: "drawer1",
            props: DrawerComponentData.DrawerProps(title: "Details", expanded: false),
            children: [
                .text(TextComponentData(id: "dt1", props: TextComponentData.TextProps(content: "Hidden content")))
            ]
        ))
        let decoded = try roundTrip(component)
        if case .drawer(let d) = decoded {
            XCTAssertEqual(d.id, "drawer1")
            XCTAssertEqual(d.props.title, "Details")
            XCTAssertFalse(d.props.expanded)
            XCTAssertEqual(d.children.count, 1)
        } else {
            XCTFail("Expected drawer component")
        }
    }

    // MARK: - CarouselComponentData with children

    func testCarouselComponentWithChildrenRoundTrip() throws {
        let component = PaywallComponent.carousel(CarouselComponentData(
            id: "car1",
            props: CarouselComponentData.CarouselProps(autoScroll: true, intervalMs: 5000),
            children: [
                .text(TextComponentData(id: "slide1", props: TextComponentData.TextProps(content: "Slide 1"))),
                .text(TextComponentData(id: "slide2", props: TextComponentData.TextProps(content: "Slide 2"))),
            ]
        ))
        let decoded = try roundTrip(component)
        if case .carousel(let d) = decoded {
            XCTAssertEqual(d.id, "car1")
            XCTAssertTrue(d.props.autoScroll)
            XCTAssertEqual(d.props.intervalMs, 5000)
            XCTAssertEqual(d.children.count, 2)
        } else {
            XCTFail("Expected carousel component")
        }
    }

    // MARK: - SlidesComponentData with pages

    func testSlidesComponentWithPagesRoundTrip() throws {
        let component = PaywallComponent.slides(SlidesComponentData(
            id: "slides1",
            props: SlidesComponentData.SlidesProps(pages: [
                [.text(TextComponentData(id: "p1t1", props: TextComponentData.TextProps(content: "Page 1")))],
                [.text(TextComponentData(id: "p2t1", props: TextComponentData.TextProps(content: "Page 2")))],
            ])
        ))
        let decoded = try roundTrip(component)
        if case .slides(let d) = decoded {
            XCTAssertEqual(d.id, "slides1")
            XCTAssertEqual(d.props.pages.count, 2)
            XCTAssertEqual(d.props.pages[0].count, 1)
            XCTAssertEqual(d.props.pages[1].count, 1)
        } else {
            XCTFail("Expected slides component")
        }
    }

    // MARK: - ToggleComponentData

    func testToggleComponentRoundTrip() throws {
        let component = PaywallComponent.toggle(ToggleComponentData(
            id: "tog1",
            props: ToggleComponentData.ToggleProps(label: "Annual billing", defaultValue: true, linkedProduct: "primary")
        ))
        let decoded = try roundTrip(component)
        if case .toggle(let d) = decoded {
            XCTAssertEqual(d.id, "tog1")
            XCTAssertEqual(d.props.label, "Annual billing")
            XCTAssertTrue(d.props.defaultValue)
            XCTAssertEqual(d.props.linkedProduct, "primary")
        } else {
            XCTFail("Expected toggle component")
        }
    }

    // MARK: - SurveyComponentData with options

    func testSurveyComponentWithOptionsRoundTrip() throws {
        let component = PaywallComponent.survey(SurveyComponentData(
            id: "survey1",
            props: SurveyComponentData.SurveyProps(
                question: "Why did you cancel?",
                options: ["Too expensive", "Missing features", "Other"],
                allowMultiple: true
            )
        ))
        let decoded = try roundTrip(component)
        if case .survey(let d) = decoded {
            XCTAssertEqual(d.id, "survey1")
            XCTAssertEqual(d.props.question, "Why did you cancel?")
            XCTAssertEqual(d.props.options, ["Too expensive", "Missing features", "Other"])
            XCTAssertTrue(d.props.allowMultiple)
        } else {
            XCTFail("Expected survey component")
        }
    }

    // MARK: - CustomViewComponentData

    func testCustomViewComponentRoundTrip() throws {
        let component = PaywallComponent.customView(CustomViewComponentData(
            id: "cv1",
            props: CustomViewComponentData.CustomViewProps(viewName: "MyCustomWidget")
        ))
        let decoded = try roundTrip(component)
        if case .customView(let d) = decoded {
            XCTAssertEqual(d.id, "cv1")
            XCTAssertEqual(d.props.viewName, "MyCustomWidget")
        } else {
            XCTFail("Expected custom_view component")
        }
    }

    // MARK: - Unknown component type

    func testUnknownComponentType() throws {
        let json = """
        {"type": "future_widget", "id": "fw1", "props": {}}
        """
        let component = try decodeComponent(json)
        if case .unknown(let type) = component {
            XCTAssertEqual(type, "future_widget")
        } else {
            XCTFail("Expected unknown component")
        }
    }

    // MARK: - Full PaywallSchema with multiple components

    func testFullPaywallSchemaRoundTrip() throws {
        let schema = PaywallSchema(
            version: "2.0",
            name: "full_test",
            settings: PaywallSettings(
                presentation: .fullscreen,
                closeButton: true,
                closeButtonDelayMs: 500,
                backgroundColor: "#111111",
                scrollEnabled: false,
                safeAreaInsets: false
            ),
            theme: PaywallTheme(
                background: "#111111",
                primary: "#FF0000",
                secondary: "#00FF00",
                textPrimary: "#FFFFFF",
                textSecondary: "#AAAAAA",
                accent: "#0000FF",
                surface: "#222222",
                cornerRadius: 16,
                fontFamily: "Helvetica"
            ),
            products: [
                ProductSlot(slot: "primary", label: "Annual", productId: "prod_1"),
                ProductSlot(slot: "secondary", label: "Monthly"),
            ],
            components: [
                .text(TextComponentData(id: "title", props: TextComponentData.TextProps(content: "Welcome"))),
                .ctaButton(CTAButtonComponentData(id: "buy", props: CTAButtonComponentData.CTAButtonProps(text: "Subscribe"))),
                .spacer(SpacerComponentData(id: "sp")),
            ]
        )

        let decoded = try roundTrip(schema)
        XCTAssertEqual(decoded.version, "2.0")
        XCTAssertEqual(decoded.name, "full_test")
        XCTAssertEqual(decoded.components.count, 3)
        XCTAssertEqual(decoded.products?.count, 2)
        XCTAssertEqual(decoded.products?[0].productId, "prod_1")
        XCTAssertNil(decoded.products?[1].productId)
        XCTAssertEqual(decoded.theme?.fontFamily, "Helvetica")
    }

    // MARK: - PaywallSettings

    func testPaywallSettingsWithAllDefaults() throws {
        let settings = PaywallSettings()
        XCTAssertEqual(settings.presentation, .modal)
        XCTAssertTrue(settings.closeButton)
        XCTAssertEqual(settings.closeButtonDelayMs, 0)
        XCTAssertEqual(settings.backgroundColor, "#FFFFFF")
        XCTAssertTrue(settings.scrollEnabled)
        XCTAssertTrue(settings.safeAreaInsets)
    }

    func testPaywallSettingsWithCustomValues() throws {
        let settings = PaywallSettings(
            presentation: .sheet,
            closeButton: false,
            closeButtonDelayMs: 2000,
            backgroundColor: "#000000",
            scrollEnabled: false,
            safeAreaInsets: false
        )
        let decoded = try roundTrip(settings)
        XCTAssertEqual(decoded.presentation, .sheet)
        XCTAssertFalse(decoded.closeButton)
        XCTAssertEqual(decoded.closeButtonDelayMs, 2000)
        XCTAssertEqual(decoded.backgroundColor, "#000000")
        XCTAssertFalse(decoded.scrollEnabled)
        XCTAssertFalse(decoded.safeAreaInsets)
    }

    func testPaywallSettingsDecodesFromPartialJSON() throws {
        let json = """
        {"presentation": "fullscreen"}
        """
        let data = json.data(using: .utf8)!
        let settings = try JSONDecoder().decode(PaywallSettings.self, from: data)
        XCTAssertEqual(settings.presentation, .fullscreen)
        XCTAssertTrue(settings.closeButton) // default
        XCTAssertEqual(settings.closeButtonDelayMs, 0) // default
    }

    // MARK: - PaywallTheme

    func testPaywallThemeRoundTrip() throws {
        let theme = PaywallTheme(
            background: "#AABBCC",
            primary: "#112233",
            secondary: "#445566",
            textPrimary: "#778899",
            textSecondary: "#AABBCC",
            accent: "#DDEEFF",
            surface: "#001122",
            cornerRadius: 20,
            fontFamily: "Menlo"
        )
        let decoded = try roundTrip(theme)
        XCTAssertEqual(decoded.background, "#AABBCC")
        XCTAssertEqual(decoded.primary, "#112233")
        XCTAssertEqual(decoded.secondary, "#445566")
        XCTAssertEqual(decoded.textPrimary, "#778899")
        XCTAssertEqual(decoded.textSecondary, "#AABBCC")
        XCTAssertEqual(decoded.accent, "#DDEEFF")
        XCTAssertEqual(decoded.surface, "#001122")
        XCTAssertEqual(decoded.cornerRadius, 20)
        XCTAssertEqual(decoded.fontFamily, "Menlo")
    }

    func testPaywallThemeDefaults() throws {
        let json = "{}"
        let data = json.data(using: .utf8)!
        let theme = try JSONDecoder().decode(PaywallTheme.self, from: data)
        XCTAssertEqual(theme.background, "#FFFFFF")
        XCTAssertEqual(theme.primary, "#007AFF")
        XCTAssertEqual(theme.cornerRadius, 12)
        XCTAssertEqual(theme.fontFamily, "system")
    }

    // MARK: - PresentationType all cases

    func testPresentationTypeAllCases() throws {
        let cases: [PresentationType] = [.modal, .fullscreen, .sheet, .inline]
        for pt in cases {
            let decoded = try roundTrip(pt)
            XCTAssertEqual(decoded, pt)
        }
    }

    // MARK: - TapBehavior all cases

    func testTapBehaviorAllCases() throws {
        let cases: [TapBehavior] = [
            .none, .purchase, .selectProduct, .restore, .close,
            .openUrl, .customAction, .customPlacement, .navigatePage, .requestReview
        ]
        for tb in cases {
            let decoded = try roundTrip(tb)
            XCTAssertEqual(decoded, tb)
        }
    }

    func testTapBehaviorRawValues() {
        XCTAssertEqual(TapBehavior.none.rawValue, "none")
        XCTAssertEqual(TapBehavior.selectProduct.rawValue, "select_product")
        XCTAssertEqual(TapBehavior.openUrl.rawValue, "open_url")
        XCTAssertEqual(TapBehavior.customAction.rawValue, "custom_action")
        XCTAssertEqual(TapBehavior.customPlacement.rawValue, "custom_placement")
        XCTAssertEqual(TapBehavior.navigatePage.rawValue, "navigate_page")
        XCTAssertEqual(TapBehavior.requestReview.rawValue, "request_review")
    }

    func testLinkRowWithNoneActionDecodesFromJSON() throws {
        let json = """
        {
            "type": "link_row",
            "id": "footer",
            "props": {
                "links": [
                    {"text": "3-day trial", "action": "none"},
                    {"text": "$29.99/yr", "action": "none"},
                    {"text": "Restore Purchase", "action": "restore"}
                ],
                "separator": " · "
            }
        }
        """.data(using: .utf8)!
        let component = try JSONDecoder().decode(PaywallComponent.self, from: json)
        if case .linkRow(let d) = component {
            XCTAssertEqual(d.props.links.count, 3)
            XCTAssertEqual(d.props.links[0].action, .none)
            XCTAssertEqual(d.props.links[1].action, .none)
            XCTAssertEqual(d.props.links[2].action, .restore)
        } else {
            XCTFail("Expected link_row component")
        }
    }

    // MARK: - CodableValue

    func testCodableValueStringRoundTrip() throws {
        let val = CodableValue.string("hello")
        let decoded = try roundTrip(val)
        if case .string(let s) = decoded {
            XCTAssertEqual(s, "hello")
        } else {
            XCTFail("Expected string CodableValue")
        }
        XCTAssertNil(val.doubleValue)
    }

    func testCodableValueNumberRoundTrip() throws {
        let val = CodableValue.number(42.5)
        let decoded = try roundTrip(val)
        if case .number(let n) = decoded {
            XCTAssertEqual(n, 42.5)
        } else {
            XCTFail("Expected number CodableValue")
        }
        XCTAssertEqual(val.doubleValue, 42.5)
    }

    // MARK: - ComponentStyle

    func testComponentStyleEncodeDecode() throws {
        var style = ComponentStyle()
        style.marginTop = 10
        style.marginBottom = 20
        style.paddingHorizontal = 16
        style.backgroundColor = "#FF0000"
        style.cornerRadius = .number(8)
        style.opacity = 0.9

        let decoded = try roundTrip(style)
        XCTAssertEqual(decoded.marginTop, 10)
        XCTAssertEqual(decoded.marginBottom, 20)
        XCTAssertEqual(decoded.paddingHorizontal, 16)
        XCTAssertEqual(decoded.backgroundColor, "#FF0000")
        XCTAssertEqual(decoded.cornerRadius?.doubleValue, 8)
        XCTAssertEqual(decoded.opacity, 0.9)
    }

    func testComponentStyleGlowColorRoundTrip() throws {
        var style = ComponentStyle()
        style.glowColor = "#FF6600"
        let decoded = try roundTrip(style)
        XCTAssertEqual(decoded.glowColor, "#FF6600")
    }

    func testComponentStyleLetterSpacingRoundTrip() throws {
        var style = ComponentStyle()
        style.letterSpacing = 2.5
        let decoded = try roundTrip(style)
        XCTAssertEqual(decoded.letterSpacing, 2.5)
    }

    func testPaywallSettingsBackgroundGradientRoundTrip() throws {
        let settings = PaywallSettings(
            backgroundGradient: BackgroundGradient(colors: ["#000000", "#FFFFFF"], direction: "vertical")
        )
        let decoded = try roundTrip(settings)
        XCTAssertNotNil(decoded.backgroundGradient)
        XCTAssertEqual(decoded.backgroundGradient?.colors, ["#000000", "#FFFFFF"])
        XCTAssertEqual(decoded.backgroundGradient?.direction, "vertical")
    }

    func testPaywallSettingsCloseButtonStyleRoundTrip() throws {
        let settings = PaywallSettings(closeButtonStyle: "text")
        let decoded = try roundTrip(settings)
        XCTAssertEqual(decoded.closeButtonStyle, "text")
    }

    func testPaywallSettingsCloseButtonStyleDefaultNil() throws {
        let settings = PaywallSettings()
        XCTAssertNil(settings.closeButtonStyle)
    }

    func testProductPickerShowPriceRoundTrip() throws {
        let component = PaywallComponent.productPicker(ProductPickerComponentData(
            id: "picker_price",
            props: ProductPickerComponentData.ProductPickerProps(
                layout: "cards",
                savingsText: "BEST VALUE",
                showPrice: false
            )
        ))
        let decoded = try roundTrip(component)
        if case .productPicker(let d) = decoded {
            XCTAssertEqual(d.props.layout, "cards")
            XCTAssertEqual(d.props.savingsText, "BEST VALUE")
            XCTAssertEqual(d.props.showPrice, false)
        } else {
            XCTFail("Expected product_picker component")
        }
    }

    // MARK: - ComponentCondition

    func testConditionDecodeOnComponent() throws {
        let json = """
        {
            "type": "text",
            "id": "t1",
            "props": {"content": "Trial text"},
            "condition": {"field": "user.has_trial", "operator": "is", "value": true}
        }
        """
        let component = try decodeComponent(json)
        if case .text(let d) = component {
            XCTAssertNotNil(d.condition)
            XCTAssertEqual(d.condition?.field, "user.has_trial")
            XCTAssertEqual(d.condition?.operator, "is")
        } else {
            XCTFail("Expected text component")
        }
    }

    // MARK: - ComponentAnimation

    func testAnimationDecodeOnComponent() throws {
        let json = """
        {
            "type": "text",
            "id": "t2",
            "props": {"content": "Animated"},
            "animation": {"type": "fade_in", "duration_ms": 300, "delay_ms": 100}
        }
        """
        let component = try decodeComponent(json)
        if case .text(let d) = component {
            XCTAssertNotNil(d.animation)
            XCTAssertEqual(d.animation?.type, "fade_in")
            XCTAssertEqual(d.animation?.durationMs, 300)
            XCTAssertEqual(d.animation?.delayMs, 100)
        } else {
            XCTFail("Expected text component")
        }
    }

    // MARK: - BackgroundGradient

    func testBackgroundGradientOnStyle() throws {
        let json = """
        {
            "colors": ["#FF0000", "#0000FF"],
            "direction": "vertical"
        }
        """
        let data = json.data(using: .utf8)!
        let gradient = try JSONDecoder().decode(BackgroundGradient.self, from: data)
        XCTAssertEqual(gradient.colors, ["#FF0000", "#0000FF"])
        XCTAssertEqual(gradient.direction, "vertical")

        let roundTripped = try roundTrip(gradient)
        XCTAssertEqual(roundTripped.colors, ["#FF0000", "#0000FF"])
        XCTAssertEqual(roundTripped.direction, "vertical")
    }

    func testComponentStyleWithGradient() throws {
        var style = ComponentStyle()
        style.backgroundGradient = BackgroundGradient(colors: ["#000", "#FFF"], direction: "horizontal")
        let decoded = try roundTrip(style)
        XCTAssertNotNil(decoded.backgroundGradient)
        XCTAssertEqual(decoded.backgroundGradient?.colors, ["#000", "#FFF"])
        XCTAssertEqual(decoded.backgroundGradient?.direction, "horizontal")
    }

    // MARK: - CustomView with customData

    func testCustomViewWithCustomData() throws {
        let json = """
        {
            "type": "custom_view",
            "id": "cv1",
            "props": {
                "view_name": "PricingCard",
                "custom_data": {"title": "Hello", "count": 42}
            }
        }
        """
        let component = try decodeComponent(json)
        if case .customView(let d) = component {
            XCTAssertEqual(d.props.viewName, "PricingCard")
            XCTAssertNotNil(d.props.customData)
            if case .string(let title) = d.props.customData?["title"] {
                XCTAssertEqual(title, "Hello")
            } else {
                XCTFail("Expected string value for title")
            }
            if case .number(let count) = d.props.customData?["count"] {
                XCTAssertEqual(count, 42)
            } else {
                XCTFail("Expected number value for count")
            }
        } else {
            XCTFail("Expected custom_view component")
        }
    }
}
