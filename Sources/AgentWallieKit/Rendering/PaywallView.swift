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
                .padding(.horizontal, 0)
            }

            if schema.settings.closeButton {
                Button(action: { onDismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding(16)
                }
            }
        }
    }

    private var backgroundColor: Color {
        let bgStr = schema.settings.backgroundColor
        return resolveColor(bgStr, theme: schema.theme) ?? Color.white
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
            CustomViewComponentView(data: data, theme: schema.theme)

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
