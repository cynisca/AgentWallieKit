import SwiftUI

/// Products section of the debug overlay.
@available(iOS 16.0, *)
struct DebugProductsView: View {
    @ObservedObject var provider: DebugDataProvider

    private let accentColor = Color(red: 0.38, green: 0.47, blue: 1.0)
    private let valueFont = Font.system(.body, design: .monospaced)
    private let bgColor = Color(red: 0.1, green: 0.1, blue: 0.18)

    var body: some View {
        List {
            if provider.products.isEmpty {
                Section {
                    Text("No products configured")
                        .foregroundColor(.gray)
                        .font(valueFont)
                        .listRowBackground(bgColor)
                }
            } else {
                ForEach(provider.products) { product in
                    Section {
                        row(label: "Name", value: product.name)
                        row(label: "Store", value: product.store)
                        row(label: "Store Product ID", value: product.storeProductId, copyable: true)
                        row(label: "Fetch Status", value: product.fetchStatus, statusColor: fetchStatusColor(product.fetchStatus))
                        row(label: "Price", value: product.resolvedPrice)
                        if !product.entitlements.isEmpty {
                            row(label: "Entitlements", value: product.entitlements.joined(separator: ", "))
                        }
                    } header: {
                        Text(product.id.uppercased())
                            .foregroundColor(accentColor)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(bgColor)
    }

    private func fetchStatusColor(_ status: String) -> Color {
        switch status {
        case "fetched": return .green
        case "failed": return .red
        case "pending": return .yellow
        default: return .white
        }
    }

    private func row(label: String, value: String, copyable: Bool = false, statusColor: Color? = nil) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
                .font(.system(.subheadline, design: .monospaced))
            Spacer()
            Text(value)
                .foregroundColor(statusColor ?? .white)
                .font(valueFont)
                .lineLimit(2)
                .truncationMode(.middle)
        }
        .listRowBackground(bgColor)
        .contentShape(Rectangle())
        .onTapGesture {
            if copyable {
                #if canImport(UIKit)
                UIPasteboard.general.string = value
                #endif
            }
        }
    }
}
