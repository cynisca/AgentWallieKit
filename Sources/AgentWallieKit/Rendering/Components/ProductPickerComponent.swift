import SwiftUI

/// Renders a product picker component from the paywall schema.
@available(iOS 16.0, *)
struct ProductPickerComponentView: View {
    let data: ProductPickerComponentData
    let products: [ProductSlot]
    let resolvedProducts: [ResolvedProductInfo]
    let theme: PaywallTheme?
    @Binding var selectedProductIndex: Int

    /// Find the resolved product info for a given slot.
    private func resolvedProduct(forSlot slot: String) -> ResolvedProductInfo? {
        resolvedProducts.first(where: { $0.slot == slot })
    }

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
            ?? Color(hex: theme?.primary ?? PaywallTheme.defaultPrimary)
    }

    private var surfaceColor: Color {
        Color(hex: theme?.surface ?? PaywallTheme.defaultSurface)
    }

    private var textPrimaryColor: Color {
        Color(hex: theme?.textPrimary ?? PaywallTheme.defaultTextPrimary)
    }

    private var textSecondaryColor: Color {
        Color(hex: theme?.textSecondary ?? PaywallTheme.defaultTextSecondary)
    }

    @ViewBuilder
    private var productButtons: some View {
        ForEach(Array(products.enumerated()), id: \.element.slot) { index, product in
            let resolved = resolvedProduct(forSlot: product.slot)
            Button(action: { selectedProductIndex = index }) {
                VStack(spacing: 4) {
                    Text(product.label)
                        .font(.subheadline)
                        .fontWeight(index == selectedProductIndex ? .bold : .regular)
                        .foregroundColor(index == selectedProductIndex ? textPrimaryColor : textSecondaryColor)

                    if let resolved = resolved, !resolved.price.isEmpty {
                        Text("\(resolved.price)\(resolved.periodLabel)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(index == selectedProductIndex ? textPrimaryColor : textSecondaryColor)
                    }

                    if let trialPeriod = resolved?.trialPeriod,
                       let trialPrice = resolved?.trialPrice {
                        Text("\(trialPeriod) \(trialPrice.lowercased()) trial")
                            .font(.caption2)
                            .foregroundColor(index == selectedProductIndex ? selectedColor : textSecondaryColor)
                    }
                }
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
                .overlay(alignment: .topTrailing) {
                    if data.props.showSavingsBadge == true,
                       let savings = resolved?.savingsPercentage {
                        Text("Save \(savings)%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedColor)
                            .cornerRadius(8)
                            .offset(x: -8, y: -8)
                    }
                }
            }
        }
    }
}
