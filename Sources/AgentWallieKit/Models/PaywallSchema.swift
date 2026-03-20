import Foundation

// MARK: - Paywall Schema

/// The full paywall JSON document that describes what to render.
public struct PaywallSchema: Codable, Sendable {
    public let version: String
    public let name: String
    public let settings: PaywallSettings
    public let theme: PaywallTheme?
    public let products: [ProductSlot]?
    public let components: [PaywallComponent]

    public init(
        version: String,
        name: String,
        settings: PaywallSettings,
        theme: PaywallTheme? = nil,
        products: [ProductSlot]? = nil,
        components: [PaywallComponent]
    ) {
        self.version = version
        self.name = name
        self.settings = settings
        self.theme = theme
        self.products = products
        self.components = components
    }
}

// MARK: - Presentation Type

public enum PresentationType: String, Codable, Sendable {
    case modal
    case fullscreen
    case sheet
    case inline
}

// MARK: - Settings

public struct PaywallSettings: Codable, Sendable {
    public let presentation: PresentationType
    public let closeButton: Bool
    public let closeButtonDelayMs: Int
    public let backgroundColor: String
    public let scrollEnabled: Bool
    public let safeAreaInsets: Bool

    public init(
        presentation: PresentationType = .modal,
        closeButton: Bool = true,
        closeButtonDelayMs: Int = 0,
        backgroundColor: String = "#FFFFFF",
        scrollEnabled: Bool = true,
        safeAreaInsets: Bool = true
    ) {
        self.presentation = presentation
        self.closeButton = closeButton
        self.closeButtonDelayMs = closeButtonDelayMs
        self.backgroundColor = backgroundColor
        self.scrollEnabled = scrollEnabled
        self.safeAreaInsets = safeAreaInsets
    }

    enum CodingKeys: String, CodingKey {
        case presentation
        case closeButton = "close_button"
        case closeButtonDelayMs = "close_button_delay_ms"
        case backgroundColor = "background_color"
        case scrollEnabled = "scroll_enabled"
        case safeAreaInsets = "safe_area_insets"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        presentation = try container.decodeIfPresent(PresentationType.self, forKey: .presentation) ?? .modal
        closeButton = try container.decodeIfPresent(Bool.self, forKey: .closeButton) ?? true
        closeButtonDelayMs = try container.decodeIfPresent(Int.self, forKey: .closeButtonDelayMs) ?? 0
        backgroundColor = try container.decodeIfPresent(String.self, forKey: .backgroundColor) ?? "#FFFFFF"
        scrollEnabled = try container.decodeIfPresent(Bool.self, forKey: .scrollEnabled) ?? true
        safeAreaInsets = try container.decodeIfPresent(Bool.self, forKey: .safeAreaInsets) ?? true
    }
}

// MARK: - Theme

public struct PaywallTheme: Codable, Sendable {
    public let background: String
    public let primary: String
    public let secondary: String
    public let textPrimary: String
    public let textSecondary: String
    public let accent: String
    public let surface: String
    public let cornerRadius: Double
    public let fontFamily: String

    public init(
        background: String = "#FFFFFF",
        primary: String = "#007AFF",
        secondary: String = "#5856D6",
        textPrimary: String = "#000000",
        textSecondary: String = "#6B7280",
        accent: String = "#34C759",
        surface: String = "#F2F2F7",
        cornerRadius: Double = 12,
        fontFamily: String = "system"
    ) {
        self.background = background
        self.primary = primary
        self.secondary = secondary
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.accent = accent
        self.surface = surface
        self.cornerRadius = cornerRadius
        self.fontFamily = fontFamily
    }

    enum CodingKeys: String, CodingKey {
        case background, primary, secondary, accent, surface
        case textPrimary = "text_primary"
        case textSecondary = "text_secondary"
        case cornerRadius = "corner_radius"
        case fontFamily = "font_family"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        background = try container.decodeIfPresent(String.self, forKey: .background) ?? "#FFFFFF"
        primary = try container.decodeIfPresent(String.self, forKey: .primary) ?? "#007AFF"
        secondary = try container.decodeIfPresent(String.self, forKey: .secondary) ?? "#5856D6"
        textPrimary = try container.decodeIfPresent(String.self, forKey: .textPrimary) ?? "#000000"
        textSecondary = try container.decodeIfPresent(String.self, forKey: .textSecondary) ?? "#6B7280"
        accent = try container.decodeIfPresent(String.self, forKey: .accent) ?? "#34C759"
        surface = try container.decodeIfPresent(String.self, forKey: .surface) ?? "#F2F2F7"
        cornerRadius = try container.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? 12
        fontFamily = try container.decodeIfPresent(String.self, forKey: .fontFamily) ?? "system"
    }
}

// MARK: - Component Style

public struct ComponentStyle: Codable, Sendable {
    public var width: CodableValue?
    public var height: CodableValue?
    public var marginTop: Double?
    public var marginBottom: Double?
    public var marginHorizontal: Double?
    public var marginLeft: Double?
    public var marginRight: Double?
    public var paddingTop: Double?
    public var paddingBottom: Double?
    public var paddingHorizontal: Double?
    public var paddingVertical: Double?
    public var paddingLeft: Double?
    public var paddingRight: Double?
    public var backgroundColor: String?
    public var color: String?
    public var textColor: String?
    public var cornerRadius: CodableValue?
    public var fontSize: Double?
    public var alignment: String?
    public var opacity: Double?
    public var borderWidth: Double?
    public var borderColor: String?

    public init() {}

    enum CodingKeys: String, CodingKey {
        case width, height, opacity
        case marginTop = "margin_top"
        case marginBottom = "margin_bottom"
        case marginHorizontal = "margin_horizontal"
        case marginLeft = "margin_left"
        case marginRight = "margin_right"
        case paddingTop = "padding_top"
        case paddingBottom = "padding_bottom"
        case paddingHorizontal = "padding_horizontal"
        case paddingVertical = "padding_vertical"
        case paddingLeft = "padding_left"
        case paddingRight = "padding_right"
        case backgroundColor = "background_color"
        case color
        case textColor = "text_color"
        case cornerRadius = "corner_radius"
        case fontSize = "font_size"
        case alignment
        case borderWidth = "border_width"
        case borderColor = "border_color"
    }
}

/// A value that can be either a string or a number.
public enum CodableValue: Codable, Sendable {
    case string(String)
    case number(Double)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let num = try? container.decode(Double.self) {
            self = .number(num)
        } else if let str = try? container.decode(String.self) {
            self = .string(str)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected string or number")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .number(let n): try container.encode(n)
        }
    }

    public var doubleValue: Double? {
        switch self {
        case .number(let n): return n
        case .string(_): return nil
        }
    }
}

// MARK: - Tap Behavior

public enum TapBehavior: String, Codable, Sendable {
    case purchase
    case selectProduct = "select_product"
    case restore
    case close
    case openUrl = "open_url"
    case customAction = "custom_action"
    case customPlacement = "custom_placement"
    case navigatePage = "navigate_page"
    case requestReview = "request_review"
}

// MARK: - Paywall Component (discriminated union via "type")

public enum PaywallComponent: Codable, Sendable {
    case text(TextComponentData)
    case image(ImageComponentData)
    case ctaButton(CTAButtonComponentData)
    case productPicker(ProductPickerComponentData)
    case featureList(FeatureListComponentData)
    case linkRow(LinkRowComponentData)
    case spacer(SpacerComponentData)
    case divider(DividerComponentData)
    case stack(StackComponentData)
    case countdownTimer(CountdownTimerComponentData)
    case unknown(String)

    enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        let singleContainer = try decoder.singleValueContainer()
        switch type {
        case "text":
            self = .text(try singleContainer.decode(TextComponentData.self))
        case "image":
            self = .image(try singleContainer.decode(ImageComponentData.self))
        case "cta_button":
            self = .ctaButton(try singleContainer.decode(CTAButtonComponentData.self))
        case "product_picker":
            self = .productPicker(try singleContainer.decode(ProductPickerComponentData.self))
        case "feature_list":
            self = .featureList(try singleContainer.decode(FeatureListComponentData.self))
        case "link_row":
            self = .linkRow(try singleContainer.decode(LinkRowComponentData.self))
        case "spacer":
            self = .spacer(try singleContainer.decode(SpacerComponentData.self))
        case "divider":
            self = .divider(try singleContainer.decode(DividerComponentData.self))
        case "stack":
            self = .stack(try singleContainer.decode(StackComponentData.self))
        case "countdown_timer":
            self = .countdownTimer(try singleContainer.decode(CountdownTimerComponentData.self))
        default:
            self = .unknown(type)
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let data): try data.encode(to: encoder)
        case .image(let data): try data.encode(to: encoder)
        case .ctaButton(let data): try data.encode(to: encoder)
        case .productPicker(let data): try data.encode(to: encoder)
        case .featureList(let data): try data.encode(to: encoder)
        case .linkRow(let data): try data.encode(to: encoder)
        case .spacer(let data): try data.encode(to: encoder)
        case .divider(let data): try data.encode(to: encoder)
        case .stack(let data): try data.encode(to: encoder)
        case .countdownTimer(let data): try data.encode(to: encoder)
        case .unknown(_): break
        }
    }
}

// MARK: - Component Data Types

public struct TextComponentData: Codable, Sendable {
    public let type: String
    public let id: String
    public let props: TextProps
    public let style: ComponentStyle?

    public init(id: String, props: TextProps, style: ComponentStyle? = nil) {
        self.type = "text"
        self.id = id
        self.props = props
        self.style = style
    }

    public struct TextProps: Codable, Sendable {
        public let content: String
        public let textStyle: String?
        public let alignment: String?

        public init(content: String, textStyle: String? = nil, alignment: String? = nil) {
            self.content = content
            self.textStyle = textStyle
            self.alignment = alignment
        }

        enum CodingKeys: String, CodingKey {
            case content
            case textStyle = "text_style"
            case alignment
        }
    }
}

public struct ImageComponentData: Codable, Sendable {
    public let type: String
    public let id: String
    public let props: ImageProps
    public let style: ComponentStyle?

    public init(id: String, props: ImageProps, style: ComponentStyle? = nil) {
        self.type = "image"
        self.id = id
        self.props = props
        self.style = style
    }

    public struct ImageProps: Codable, Sendable {
        public let src: String
        public let alt: String?
        public let aspectRatio: String?
        public let fit: String?

        public init(src: String, alt: String? = nil, aspectRatio: String? = nil, fit: String? = nil) {
            self.src = src
            self.alt = alt
            self.aspectRatio = aspectRatio
            self.fit = fit
        }

        enum CodingKeys: String, CodingKey {
            case src, alt, fit
            case aspectRatio = "aspect_ratio"
        }
    }
}

public struct CTAButtonComponentData: Codable, Sendable {
    public let type: String
    public let id: String
    public let props: CTAButtonProps
    public let style: ComponentStyle?

    public init(id: String, props: CTAButtonProps, style: ComponentStyle? = nil) {
        self.type = "cta_button"
        self.id = id
        self.props = props
        self.style = style
    }

    public struct CTAButtonProps: Codable, Sendable {
        public let text: String
        public let subtitle: String?
        public let action: TapBehavior
        public let product: String?
        public let url: String?
        public let actionName: String?
        public let placementName: String?

        public init(
            text: String,
            subtitle: String? = nil,
            action: TapBehavior = .purchase,
            product: String? = nil,
            url: String? = nil,
            actionName: String? = nil,
            placementName: String? = nil
        ) {
            self.text = text
            self.subtitle = subtitle
            self.action = action
            self.product = product
            self.url = url
            self.actionName = actionName
            self.placementName = placementName
        }

        enum CodingKeys: String, CodingKey {
            case text, subtitle, action, product, url
            case actionName = "action_name"
            case placementName = "placement_name"
        }
    }
}

public struct ProductPickerComponentData: Codable, Sendable {
    public let type: String
    public let id: String
    public let props: ProductPickerProps
    public let style: ComponentStyle?

    public init(id: String, props: ProductPickerProps, style: ComponentStyle? = nil) {
        self.type = "product_picker"
        self.id = id
        self.props = props
        self.style = style
    }

    public struct ProductPickerProps: Codable, Sendable {
        public let layout: String
        public let showSavingsBadge: Bool?
        public let savingsText: String?
        public let selectedBorderColor: String?

        public init(
            layout: String = "horizontal",
            showSavingsBadge: Bool? = nil,
            savingsText: String? = nil,
            selectedBorderColor: String? = nil
        ) {
            self.layout = layout
            self.showSavingsBadge = showSavingsBadge
            self.savingsText = savingsText
            self.selectedBorderColor = selectedBorderColor
        }

        enum CodingKeys: String, CodingKey {
            case layout
            case showSavingsBadge = "show_savings_badge"
            case savingsText = "savings_text"
            case selectedBorderColor = "selected_border_color"
        }
    }
}

public struct FeatureListComponentData: Codable, Sendable {
    public let type: String
    public let id: String
    public let props: FeatureListProps
    public let style: ComponentStyle?

    public init(id: String, props: FeatureListProps, style: ComponentStyle? = nil) {
        self.type = "feature_list"
        self.id = id
        self.props = props
        self.style = style
    }

    public struct FeatureListProps: Codable, Sendable {
        public let items: [FeatureItem]
        public let iconColor: String?

        public init(items: [FeatureItem], iconColor: String? = nil) {
            self.items = items
            self.iconColor = iconColor
        }

        enum CodingKeys: String, CodingKey {
            case items
            case iconColor = "icon_color"
        }
    }

    public struct FeatureItem: Codable, Sendable {
        public let icon: String
        public let text: String

        public init(icon: String, text: String) {
            self.icon = icon
            self.text = text
        }
    }
}

public struct LinkRowComponentData: Codable, Sendable {
    public let type: String
    public let id: String
    public let props: LinkRowProps
    public let style: ComponentStyle?

    public init(id: String, props: LinkRowProps, style: ComponentStyle? = nil) {
        self.type = "link_row"
        self.id = id
        self.props = props
        self.style = style
    }

    public struct LinkRowProps: Codable, Sendable {
        public let links: [LinkItem]
        public let separator: String?

        public init(links: [LinkItem], separator: String? = nil) {
            self.links = links
            self.separator = separator
        }
    }

    public struct LinkItem: Codable, Sendable {
        public let text: String
        public let action: TapBehavior
        public let url: String?

        public init(text: String, action: TapBehavior, url: String? = nil) {
            self.text = text
            self.action = action
            self.url = url
        }
    }
}

// MARK: - Spacer Component

public struct SpacerComponentData: Codable, Sendable {
    public let type: String
    public let id: String
    public let style: ComponentStyle?

    public init(id: String, style: ComponentStyle? = nil) {
        self.type = "spacer"
        self.id = id
        self.style = style
    }
}

// MARK: - Divider Component

public struct DividerComponentData: Codable, Sendable {
    public let type: String
    public let id: String
    public let props: DividerProps?
    public let style: ComponentStyle?

    public init(id: String, props: DividerProps? = nil, style: ComponentStyle? = nil) {
        self.type = "divider"
        self.id = id
        self.props = props
        self.style = style
    }

    public struct DividerProps: Codable, Sendable {
        public let color: String?
        public let thickness: Double?

        public init(color: String? = nil, thickness: Double? = nil) {
            self.color = color
            self.thickness = thickness
        }
    }
}

// MARK: - Stack Component

public struct StackComponentData: Codable, Sendable {
    public let type: String
    public let id: String
    public let props: StackProps
    public let children: [PaywallComponent]
    public let style: ComponentStyle?

    public init(id: String, props: StackProps, children: [PaywallComponent], style: ComponentStyle? = nil) {
        self.type = "stack"
        self.id = id
        self.props = props
        self.children = children
        self.style = style
    }

    public struct StackProps: Codable, Sendable {
        public let direction: String
        public let spacing: Double?
        public let alignment: String?

        public init(direction: String = "vertical", spacing: Double? = nil, alignment: String? = nil) {
            self.direction = direction
            self.spacing = spacing
            self.alignment = alignment
        }
    }
}

// MARK: - Countdown Timer Component

public struct CountdownTimerComponentData: Codable, Sendable {
    public let type: String
    public let id: String
    public let props: CountdownTimerProps
    public let style: ComponentStyle?

    public init(id: String, props: CountdownTimerProps, style: ComponentStyle? = nil) {
        self.type = "countdown_timer"
        self.id = id
        self.props = props
        self.style = style
    }

    public struct CountdownTimerProps: Codable, Sendable {
        public let durationSeconds: Int
        public let label: String?

        public init(durationSeconds: Int, label: String? = nil) {
            self.durationSeconds = durationSeconds
            self.label = label
        }

        enum CodingKeys: String, CodingKey {
            case durationSeconds = "duration_seconds"
            case label
        }
    }
}
