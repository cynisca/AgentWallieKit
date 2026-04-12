#if DEBUG
import SwiftUI

/// A debug-only SwiftUI view for previewing a PaywallSchema locally.
/// Use this during development to iterate on paywall schemas without
/// the full publish → fetch → render cycle.
///
/// Usage:
/// ```swift
/// struct MyPreview: PreviewProvider {
///     static var previews: some View {
///         PaywallPreviewView(schema: mySchema)
///     }
/// }
/// ```
@available(iOS 16.0, *)
public struct PaywallPreviewView: View {
    let schema: PaywallSchema
    let mockProducts: [ResolvedProductInfo]

    /// Initialize with a schema and optional mock products.
    /// If mockProducts is nil, default stubs are generated from the schema's product slots.
    public init(schema: PaywallSchema, mockProducts: [ResolvedProductInfo]? = nil) {
        self.schema = schema
        self.mockProducts = mockProducts ?? Self.defaultMockProducts(for: schema)
    }

    public var body: some View {
        PaywallView(
            schema: schema,
            resolvedProducts: mockProducts,
            onAction: { action, param in
                print("[PaywallPreviewView] Action: \(action), param: \(param ?? "nil")")
            },
            onDismiss: {
                print("[PaywallPreviewView] Dismissed")
            }
        )
    }

    /// Generate stub ResolvedProductInfo for each product slot in the schema.
    private static func defaultMockProducts(for schema: PaywallSchema) -> [ResolvedProductInfo] {
        guard let slots = schema.products else { return [] }
        return slots.enumerated().map { (index, slot) in
            ResolvedProductInfo(
                slot: slot.slot,
                label: slot.label,
                productId: slot.productId,
                storeProductId: slot.productId ?? "com.example.\(slot.slot)",
                price: index == 0 ? "$9.99" : "$59.99",
                pricePerMonth: index == 0 ? "$9.99" : "$5.00",
                period: index == 0 ? "month" : "year",
                periodLabel: index == 0 ? "/mo" : "/yr",
                savingsPercentage: index == 0 ? nil : 50
            )
        }
    }
}
#endif
