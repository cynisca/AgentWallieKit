import SwiftUI

/// Renders a multi-page slides view with page indicator dots.
@available(iOS 16.0, *)
struct SlidesComponentView: View {
    let data: SlidesComponentData
    let theme: PaywallTheme?
    let onAction: (TapBehavior, String?) -> Void
    let renderComponent: (PaywallComponent) -> AnyView

    @State private var currentPage: Int = 0

    var body: some View {
        VStack(spacing: 8) {
            TabView(selection: $currentPage) {
                ForEach(Array(data.props.pages.enumerated()), id: \.offset) { pageIndex, page in
                    VStack(spacing: 0) {
                        ForEach(Array(page.enumerated()), id: \.offset) { _, component in
                            renderComponent(component)
                        }
                    }
                    .tag(pageIndex)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .frame(minHeight: 200)

            // Page indicator dots
            if data.props.pages.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<data.props.pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage
                                ? Color(hex: theme?.primary ?? "#007AFF")
                                : Color(hex: theme?.textSecondary ?? "#6B7280").opacity(0.4))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 4)
            }
        }
        .modifier(StyleModifier(style: data.style, theme: theme))
    }
}
