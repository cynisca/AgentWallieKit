import SwiftUI

/// Renders a toggle switch with an optional linked product selection.
@available(iOS 16.0, *)
struct ToggleComponentView: View {
    let data: ToggleComponentData
    let theme: PaywallTheme?
    let onAction: (TapBehavior, String?) -> Void

    @State private var isOn: Bool

    init(
        data: ToggleComponentData,
        theme: PaywallTheme?,
        onAction: @escaping (TapBehavior, String?) -> Void
    ) {
        self.data = data
        self.theme = theme
        self.onAction = onAction
        self._isOn = State(initialValue: data.props.defaultValue)
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(data.props.label)
                .foregroundColor(resolveColor(data.style?.textColor, theme: theme) ?? .primary)
        }
        .tint(resolveColor(data.style?.color, theme: theme))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .modifier(StyleModifier(style: data.style, theme: theme))
        .onChange(of: isOn) { newValue in
            if let linkedProduct = data.props.linkedProduct, newValue {
                onAction(.selectProduct, linkedProduct)
            }
        }
    }
}
