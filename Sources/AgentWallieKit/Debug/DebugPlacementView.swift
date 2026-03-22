import SwiftUI

/// Placement evaluator section of the debug overlay.
@available(iOS 16.0, *)
struct DebugPlacementView: View {
    @ObservedObject var provider: DebugDataProvider
    @State private var placementName: String = ""

    /// Closure that performs a dry evaluation of a placement and returns a result string.
    var onEvaluate: ((String) -> String)?

    private let accentColor = Color(red: 0.38, green: 0.47, blue: 1.0)
    private let valueFont = Font.system(.body, design: .monospaced)
    private let bgColor = Color(red: 0.1, green: 0.1, blue: 0.18)

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Placement name", text: $placementName)
                        .foregroundColor(.white)
                        .font(valueFont)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif

                    Button("Evaluate") {
                        if let evaluate = onEvaluate, !placementName.isEmpty {
                            provider.placementResult = evaluate(placementName)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accentColor)
                    .disabled(placementName.isEmpty)
                }
                .listRowBackground(bgColor)
            } header: {
                Text("PLACEMENT EVALUATOR")
                    .foregroundColor(accentColor)
                    .font(.system(.caption, design: .monospaced))
            }

            if !provider.placementResult.isEmpty {
                Section {
                    Text(provider.placementResult)
                        .foregroundColor(.white)
                        .font(valueFont)
                        .listRowBackground(bgColor)
                        .textSelection(.enabled)
                } header: {
                    Text("RESULT")
                        .foregroundColor(accentColor)
                        .font(.system(.caption, design: .monospaced))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(bgColor)
    }
}
