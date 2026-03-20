import SwiftUI

/// Renders a horizontal scrollable carousel with page indicator dots.
@available(iOS 16.0, *)
struct CarouselComponentView: View {
    let data: CarouselComponentData
    let theme: PaywallTheme?
    let onAction: (TapBehavior, String?) -> Void
    let renderComponent: (PaywallComponent) -> AnyView

    @State private var currentPage: Int = 0

    var body: some View {
        VStack(spacing: 8) {
            TabView(selection: $currentPage) {
                ForEach(Array(data.children.enumerated()), id: \.offset) { index, child in
                    renderComponent(child)
                        .tag(index)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .frame(minHeight: 200)

            // Page indicator dots
            if data.children.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<data.children.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage
                                ? Color(hex: theme?.primary ?? PaywallTheme.defaultPrimary)
                                : Color(hex: theme?.textSecondary ?? PaywallTheme.defaultTextSecondary).opacity(0.4))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 4)
            }
        }
        .modifier(StyleModifier(style: data.style, theme: theme))
        .onAppear {
            if data.props.autoScroll && data.children.count > 1 {
                startAutoScroll()
            }
        }
    }

    private func startAutoScroll() {
        let interval = Double(data.props.intervalMs) / 1000.0
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            withAnimation {
                currentPage = (currentPage + 1) % data.children.count
            }
        }
    }
}
