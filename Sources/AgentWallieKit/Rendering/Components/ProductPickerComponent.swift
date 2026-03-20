import SwiftUI

/// Renders a product picker component from the paywall schema.
@available(iOS 16.0, *)
struct ProductPickerComponentView: View {
    let data: ProductPickerComponentData
    let products: [ProductSlot]
    let theme: PaywallTheme?
    @Binding var selectedProductIndex: Int

    var body: some View {
        Group {
            if data.props.layout == "vertical" {
                VStack(spacing: 12) {
                    productButtons
                }
            } else {
                HStack(spacing: 12) {
                    productButtons
                }
            }
        }
        .modifier(StyleModifier(style: data.style, theme: theme))
    }

    private var selectedColor: Color {
        resolveColor(data.props.selectedBorderColor, theme: theme)
            ?? Color(hex: theme?.primary ?? "#007AFF")
    }

    private var surfaceColor: Color {
        Color(hex: theme?.surface ?? "#F2F2F7")
    }

    private var textPrimaryColor: Color {
        Color(hex: theme?.textPrimary ?? "#000000")
    }

    private var textSecondaryColor: Color {
        Color(hex: theme?.textSecondary ?? "#6B7280")
    }

    @ViewBuilder
    private var productButtons: some View {
        ForEach(Array(products.enumerated()), id: \.element.slot) { index, product in
            Button(action: { selectedProductIndex = index }) {
                Text(product.label)
                    .font(.subheadline)
                    .fontWeight(index == selectedProductIndex ? .bold : .regular)
                    .foregroundColor(index == selectedProductIndex ? textPrimaryColor : textSecondaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: CGFloat(theme?.cornerRadius ?? 12))
                            .fill(surfaceColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CGFloat(theme?.cornerRadius ?? 12))
                            .stroke(
                                index == selectedProductIndex
                                    ? selectedColor
                                    : Color.clear,
                                lineWidth: 2
                            )
                    )
            }
        }
    }
}
