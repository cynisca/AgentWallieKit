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

    /// Whether to show price info (default true).
    private var showPrice: Bool {
        data.props.showPrice ?? true
    }

    var body: some View {
        Group {
            if data.props.layout == "cards" {
                HStack(spacing: 12) {
                    cardButtons
                }
            } else if data.props.layout == "vertical" {
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

    private var componentFontFamily: String? {
        data.style?.fontFamily
    }

    // MARK: - Standard Layout (horizontal/vertical)

    @ViewBuilder
    private var productButtons: some View {
        ForEach(Array(products.enumerated()), id: \.element.slot) { index, product in
            let resolved = resolvedProduct(forSlot: product.slot)
            Button(action: { selectedProductIndex = index }) {
                VStack(spacing: 4) {
                    Text(product.label)
                        .font(resolveFont(textStyle: "subheadline", fontSize: nil, fontFamily: componentFontFamily, theme: theme))
                        .fontWeight(index == selectedProductIndex ? .bold : .regular)
                        .foregroundColor(index == selectedProductIndex ? textPrimaryColor : textSecondaryColor)

                    if showPrice, let resolved = resolved, !resolved.price.isEmpty {
                        Text("\(resolved.price)\(resolved.periodLabel)")
                            .font(resolveFont(textStyle: "caption", fontSize: nil, fontFamily: componentFontFamily, theme: theme))
                            .fontWeight(.medium)
                            .foregroundColor(index == selectedProductIndex ? textPrimaryColor : textSecondaryColor)
                    }

                    if let trialPeriod = resolved?.trialPeriod,
                       let trialPrice = resolved?.trialPrice {
                        Text("\(trialPeriod) \(trialPrice.lowercased()) trial")
                            .font(resolveFont(textStyle: "caption2", fontSize: nil, fontFamily: componentFontFamily, theme: theme))
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
                            .font(resolveFont(textStyle: "caption2", fontSize: nil, fontFamily: componentFontFamily, theme: theme))
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

    // MARK: - Cards Layout

    @ViewBuilder
    private var cardButtons: some View {
        ForEach(Array(products.enumerated()), id: \.element.slot) { index, product in
            let resolved = resolvedProduct(forSlot: product.slot)
            let isSelected = index == selectedProductIndex
            let cr = CGFloat(theme?.cornerRadius ?? 12)

            Button(action: { selectedProductIndex = index }) {
                VStack(spacing: 8) {
                    // Plan label in caps
                    Text(product.label.uppercased())
                        .font(resolveFont(textStyle: "caption", fontSize: nil, fontFamily: componentFontFamily, theme: theme))
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? selectedColor : textSecondaryColor)
                        .tracking(1)

                    if showPrice {
                        // Large price
                        Text(resolved?.price ?? "")
                            .font(resolveFont(textStyle: "title1", fontSize: nil, fontFamily: componentFontFamily, theme: theme))
                            .fontWeight(.bold)
                            .foregroundColor(textPrimaryColor)

                        // Period subtext
                        if let periodLabel = resolved?.periodLabel, !periodLabel.isEmpty {
                            Text(periodLabel)
                                .font(resolveFont(textStyle: "caption", fontSize: nil, fontFamily: componentFontFamily, theme: theme))
                                .foregroundColor(textSecondaryColor)
                        }

                        // Savings percentage in accent
                        if let savings = resolved?.savingsPercentage {
                            Text("Save \(savings)%")
                                .font(resolveFont(textStyle: "caption2", fontSize: nil, fontFamily: componentFontFamily, theme: theme))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: theme?.accent ?? PaywallTheme.defaultAccent))
                        }
                    }

                    // Trial info
                    if let trialPeriod = resolved?.trialPeriod,
                       let trialPrice = resolved?.trialPrice {
                        Text("\(trialPeriod) \(trialPrice.lowercased()) trial")
                            .font(resolveFont(textStyle: "caption2", fontSize: nil, fontFamily: componentFontFamily, theme: theme))
                            .foregroundColor(isSelected ? selectedColor : textSecondaryColor)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: cr)
                        .fill(surfaceColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cr)
                        .stroke(isSelected ? selectedColor : Color.clear, lineWidth: 2)
                )
                .applyIf(isSelected) { view in
                    view.shadow(color: selectedColor.opacity(0.4), radius: 12, x: 0, y: 4)
                }
            }
            .overlay(alignment: .top) {
                // Badge overlapping top edge
                if let badgeText = badgeText(forIndex: index, resolved: resolved) {
                    Text(badgeText)
                        .font(resolveFont(textStyle: "caption2", fontSize: nil, fontFamily: componentFontFamily, theme: theme))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(selectedColor)
                        .cornerRadius(8)
                        .offset(y: -10)
                }
            }
        }
    }

    /// Determine badge text for a card. Uses custom `savings_text` if provided,
    /// otherwise falls back to "BEST VALUE" for the product with highest savings.
    private func badgeText(forIndex index: Int, resolved: ResolvedProductInfo?) -> String? {
        // Custom savings_text applies to the first product with savings
        if let customText = data.props.savingsText {
            if let savings = resolved?.savingsPercentage, savings > 0 {
                return customText
            }
            return nil
        }
        // Default: show "BEST VALUE" on product with savings
        if let savings = resolved?.savingsPercentage, savings > 0 {
            return "BEST VALUE"
        }
        return nil
    }
}
