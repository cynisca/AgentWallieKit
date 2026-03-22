import SwiftUI

/// User Info section of the debug overlay.
@available(iOS 16.0, *)
struct DebugUserView: View {
    @ObservedObject var provider: DebugDataProvider

    private let accentColor = Color(red: 0.38, green: 0.47, blue: 1.0)
    private let valueFont = Font.system(.body, design: .monospaced)
    private let bgColor = Color(red: 0.1, green: 0.1, blue: 0.18)

    var body: some View {
        List {
            Section {
                row(label: "User ID", value: provider.userId, copyable: true)
                row(label: "Type", value: provider.isIdentified ? "Identified" : "Anonymous (Device ID)")
                row(label: "Subscription", value: provider.subscriptionStatus)
                row(label: "Seed", value: "\(provider.userSeed)")
            } header: {
                Text("USER IDENTITY")
                    .foregroundColor(accentColor)
                    .font(.system(.caption, design: .monospaced))
            }

            if !provider.activeEntitlements.isEmpty {
                Section {
                    ForEach(provider.activeEntitlements, id: \.self) { entitlement in
                        Text(entitlement)
                            .foregroundColor(.white)
                            .font(valueFont)
                            .listRowBackground(bgColor)
                    }
                } header: {
                    Text("ACTIVE ENTITLEMENTS")
                        .foregroundColor(accentColor)
                        .font(.system(.caption, design: .monospaced))
                }
            }

            if !provider.userAttributes.isEmpty {
                Section {
                    ForEach(provider.userAttributes.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        row(label: key, value: value)
                    }
                } header: {
                    Text("USER ATTRIBUTES")
                        .foregroundColor(accentColor)
                        .font(.system(.caption, design: .monospaced))
                }
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
}
