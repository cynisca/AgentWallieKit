import SwiftUI

/// The main SwiftUI paywall renderer.
/// Takes a PaywallSchema and renders all components natively.
@available(iOS 16.0, *)
public struct PaywallView: View {
    let schema: PaywallSchema
    let onAction: (TapBehavior, String?) -> Void
    let onDismiss: () -> Void

    @State private var selectedProductIndex: Int = 0

    public init(
        schema: PaywallSchema,
        onAction: @escaping (TapBehavior, String?) -> Void = { _, _ in },
        onDismiss: @escaping () -> Void = {}
    ) {
        self.schema = schema
        self.onAction = onAction
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            backgroundColor
                .ignoresSafeArea()

            ScrollView(schema.settings.scrollEnabled ? .vertical : []) {
                VStack(spacing: 0) {
                    ForEach(Array(schema.components.enumerated()), id: \.offset) { _, component in
                        renderComponent(component)
                    }
                }
                .padding(.horizontal, 16)
            }
            .foregroundColor(Color(hex: schema.theme?.textPrimary ?? "#000000"))
            .applyIf(!schema.settings.safeAreaInsets) { view in
                view.ignoresSafeArea()
            }

            if schema.settings.closeButton {
                Button(action: { onDismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(closeButtonForeground)
                        .frame(width: 30, height: 30)
                        .background(closeButtonBackground)
                        .clipShape(Circle())
                        .padding(16)
                }
            }
        }
    }

    private var backgroundColor: Color {
        let bgStr = schema.settings.backgroundColor
        // Try to resolve the background color (handles both hex and theme refs)
        if let resolved = resolveColor(bgStr, theme: schema.theme) {
            return resolved
        }
        // Fall back to theme.background
        return Color(hex: schema.theme?.background ?? "#FFFFFF")
    }

    private var closeButtonForeground: Color {
        // Use a contrasting color based on background
        return Color(hex: schema.theme?.textPrimary ?? "#000000")
    }

    private var closeButtonBackground: Color {
        // Semi-transparent overlay that works on both light and dark backgrounds
        return Color(hex: schema.theme?.textPrimary ?? "#000000").opacity(0.15)
    }

    @ViewBuilder
    private func renderComponent(_ component: PaywallComponent) -> some View {
        switch component {
        case .text(let data):
            TextComponentView(data: data, theme: schema.theme)

        case .image(let data):
            ImageComponentView(data: data, theme: schema.theme)

        case .ctaButton(let data):
            CTAButtonComponentView(data: data, theme: schema.theme, onAction: handleAction)

        case .productPicker(let data):
            ProductPickerComponentView(
                data: data,
                products: schema.products ?? [],
                theme: schema.theme,
                selectedProductIndex: $selectedProductIndex
            )

        case .featureList(let data):
            FeatureListComponentView(data: data, theme: schema.theme)

        case .linkRow(let data):
            LinkRowComponentView(data: data, theme: schema.theme, onAction: handleAction)

        case .spacer(let data):
            SpacerComponentView(data: data, theme: schema.theme)

        case .divider(let data):
            DividerComponentView(data: data, theme: schema.theme)

        case .stack(let data):
            StackComponentView(
                data: data,
                theme: schema.theme,
                onAction: handleAction,
                renderComponent: { child in AnyView(renderComponent(child)) }
            )

        case .countdownTimer(let data):
            CountdownTimerComponentView(data: data, theme: schema.theme)

        case .video(let data):
            VideoComponentView(data: data, theme: schema.theme)

        case .drawer(let data):
            DrawerComponentView(
                data: data,
                theme: schema.theme,
                onAction: handleAction,
                renderComponent: { child in AnyView(renderComponent(child)) }
            )

        case .carousel(let data):
            CarouselComponentView(
                data: data,
                theme: schema.theme,
                onAction: handleAction,
                renderComponent: { child in AnyView(renderComponent(child)) }
            )

        case .slides(let data):
            SlidesComponentView(
                data: data,
                theme: schema.theme,
                onAction: handleAction,
                renderComponent: { child in AnyView(renderComponent(child)) }
            )

        case .toggle(let data):
            ToggleComponentView(data: data, theme: schema.theme, onAction: handleAction)

        case .survey(let data):
            SurveyComponentView(data: data, theme: schema.theme, onAction: handleAction)

        case .customView(let data):
            CustomViewComponentView(
                data: data,
                theme: schema.theme,
                products: schema.products,
                userAttributes: [:],  // TODO: wire from UserManager
                onAction: handleAction
            )

        case .badge(let data):
            BadgeComponentView(data: data, theme: schema.theme)

        case .rating(let data):
            RatingComponentView(data: data, theme: schema.theme)

        case .unknown:
            EmptyView()
        }
    }

    private func handleAction(_ action: TapBehavior, _ param: String?) {
        switch action {
        case .close:
            onDismiss()
        default:
            onAction(action, param)
        }
    }
}
