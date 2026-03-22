import SwiftUI

/// SDK Status section of the debug overlay.
@available(iOS 16.0, *)
struct DebugStatusView: View {
    @ObservedObject var provider: DebugDataProvider

    private let accentColor = Color(red: 0.38, green: 0.47, blue: 1.0)
    private let valueFont = Font.system(.body, design: .monospaced)
    private let bgColor = Color(red: 0.1, green: 0.1, blue: 0.18)

    var body: some View {
        List {
            Section {
                row(label: "Configured", value: provider.isConfigured ? "yes" : "no")
                row(label: "API Key", value: provider.apiKey, copyable: true)
                row(label: "API Base URL", value: provider.apiBaseURL, copyable: true)
                row(label: "Config Status", value: provider.configStatus)
                if let lastFetched = provider.configLastFetched {
                    row(label: "Last Fetched", value: formatDate(lastFetched))
                }
                row(label: "Campaigns", value: "\(provider.campaignsCount)")
                row(label: "Paywalls", value: "\(provider.paywallsCount)")
                row(label: "Products", value: "\(provider.productsCount)")
            } header: {
                Text("SDK STATUS")
                    .foregroundColor(accentColor)
                    .font(.system(.caption, design: .monospaced))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(bgColor)
    }

    private func row(label: String, value: String, copyable: Bool = false) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
                .font(.system(.subheadline, design: .monospaced))
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .font(valueFont)
                .lineLimit(1)
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}
