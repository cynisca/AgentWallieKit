import SwiftUI

/// Renders a collapsible drawer / expandable section with a tap-to-toggle header.
@available(iOS 16.0, *)
struct DrawerComponentView: View {
    let data: DrawerComponentData
    let theme: PaywallTheme?
    let onAction: (TapBehavior, String?) -> Void
    let renderComponent: (PaywallComponent) -> AnyView

    @State private var isExpanded: Bool

    init(
        data: DrawerComponentData,
        theme: PaywallTheme?,
        onAction: @escaping (TapBehavior, String?) -> Void,
        renderComponent: @escaping (PaywallComponent) -> AnyView
    ) {
        self.data = data
        self.theme = theme
        self.onAction = onAction
        self.renderComponent = renderComponent
        self._isExpanded = State(initialValue: data.props.expanded)
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(data.props.title)
                        .font(.headline)
                        .foregroundColor(resolveColor(data.style?.textColor, theme: theme) ?? .primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(data.children.enumerated()), id: \.offset) { _, child in
                        renderComponent(child)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .modifier(StyleModifier(style: data.style))
    }
}
