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
        .modifier(StyleModifier(style: data.style))
    }

    @ViewBuilder
    private var productButtons: some View {
        ForEach(Array(products.enumerated()), id: \.element.slot) { index, product in
            Button(action: { selectedProductIndex = index }) {
                Text(product.label)
                    .font(.subheadline)
                    .fontWeight(index == selectedProductIndex ? .bold : .regular)
                    .foregroundColor(index == selectedProductIndex ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: CGFloat(theme?.cornerRadius ?? 12))
                            .fill(index == selectedProductIndex
                                ? (resolveColor(data.props.selectedBorderColor, theme: theme) ?? Color.blue)
                                : Color.gray.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CGFloat(theme?.cornerRadius ?? 12))
                            .stroke(
                                index == selectedProductIndex
                                    ? (resolveColor(data.props.selectedBorderColor, theme: theme) ?? Color.blue)
                                    : Color.clear,
                                lineWidth: 2
                            )
                    )
            }
        }
    }
}
