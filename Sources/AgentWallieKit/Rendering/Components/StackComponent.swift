import SwiftUI

/// Renders a VStack or HStack based on direction, recursively rendering children.
@available(iOS 16.0, *)
struct StackComponentView: View {
    let data: StackComponentData
    let theme: PaywallTheme?
    let onAction: (TapBehavior, String?) -> Void
    let renderComponent: (PaywallComponent) -> AnyView

    var body: some View {
        let spacing = data.props.spacing.map { CGFloat($0) } ?? 0

        Group {
            if data.props.direction == "horizontal" {
                HStack(alignment: verticalCrossAxisAlignment, spacing: spacing) {
                    ForEach(Array(data.children.enumerated()), id: \.offset) { _, child in
                        renderComponent(child)
                    }
                }
            } else if data.props.direction == "z" {
                ZStack(alignment: zStackAlignment) {
                    ForEach(Array(data.children.enumerated()), id: \.offset) { _, child in
                        renderComponent(child)
                    }
                }
            } else {
                VStack(alignment: horizontalCrossAxisAlignment, spacing: spacing) {
                    ForEach(Array(data.children.enumerated()), id: \.offset) { _, child in
                        renderComponent(child)
                    }
                }
            }
        }
        .modifier(StyleModifier(style: data.style, theme: theme))
    }

    /// Cross-axis alignment for VStack (horizontal axis).
    private var horizontalCrossAxisAlignment: HorizontalAlignment {
        switch data.props.alignment {
        case "leading": return .leading
        case "trailing": return .trailing
        default: return .center
        }
    }

    /// Cross-axis alignment for HStack (vertical axis).
    private var verticalCrossAxisAlignment: VerticalAlignment {
        switch data.props.alignment {
        case "top": return .top
        case "bottom": return .bottom
        default: return .center
        }
    }

    private var zStackAlignment: Alignment {
        switch data.props.alignment {
        case "center": return .center
        case "top": return .top
        case "bottom": return .bottom
        case "leading": return .leading
        case "trailing": return .trailing
        case "topLeading": return .topLeading
        case "topTrailing": return .topTrailing
        case "bottomLeading": return .bottomLeading
        case "bottomTrailing": return .bottomTrailing
        default: return .center
        }
    }
}
