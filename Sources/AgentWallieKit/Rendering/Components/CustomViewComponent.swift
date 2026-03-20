import SwiftUI

/// Renders a placeholder for a custom native view injection point.
@available(iOS 16.0, *)
struct CustomViewComponentView: View {
    let data: CustomViewComponentData
    let theme: PaywallTheme?

    var body: some View {
        VStack {
            Text("Custom: \(data.props.viewName)")
                .font(.subheadline)
                .foregroundColor(resolveColor(data.style?.textColor, theme: theme) ?? .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(resolveColor(data.style?.borderColor, theme: theme) ?? Color.secondary.opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .modifier(StyleModifier(style: data.style, theme: theme))
    }
}
