import SwiftUI

/// Experiment assignments section of the debug overlay.
@available(iOS 16.0, *)
struct DebugAssignmentsView: View {
    @ObservedObject var provider: DebugDataProvider

    private let accentColor = Color(red: 0.38, green: 0.47, blue: 1.0)
    private let valueFont = Font.system(.body, design: .monospaced)
    private let bgColor = Color(red: 0.1, green: 0.1, blue: 0.18)

    var body: some View {
        List {
            if provider.assignments.isEmpty {
                Section {
                    Text("No experiment assignments")
                        .foregroundColor(.gray)
                        .font(valueFont)
                        .listRowBackground(bgColor)
                }
            } else {
                ForEach(provider.assignments) { assignment in
                    Section {
                        row(label: "Experiment ID", value: assignment.experimentId, copyable: true)
                        row(label: "Variant ID", value: assignment.variantId ?? "(none)")
                        row(label: "Paywall ID", value: assignment.paywallId ?? "(none)", copyable: true)
                        row(label: "Holdout", value: assignment.isHoldout ? "yes" : "no",
                            statusColor: assignment.isHoldout ? .yellow : .green)
                    } header: {
                        Text("EXPERIMENT")
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

    private func row(label: String, value: String, copyable: Bool = false, statusColor: Color? = nil) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
                .font(.system(.subheadline, design: .monospaced))
            Spacer()
            Text(value)
                .foregroundColor(statusColor ?? .white)
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
