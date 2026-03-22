import SwiftUI

/// Event log section of the debug overlay.
@available(iOS 16.0, *)
struct DebugEventLogView: View {
    @ObservedObject var provider: DebugDataProvider

    private let accentColor = Color(red: 0.38, green: 0.47, blue: 1.0)
    private let valueFont = Font.system(.body, design: .monospaced)
    private let bgColor = Color(red: 0.1, green: 0.1, blue: 0.18)

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    var body: some View {
        List {
            if provider.recentEvents.isEmpty {
                Section {
                    Text("No events recorded yet")
                        .foregroundColor(.gray)
                        .font(valueFont)
                        .listRowBackground(bgColor)
                }
            } else {
                Section {
                    Text("\(provider.recentEvents.count) events (max 50)")
                        .foregroundColor(.gray)
                        .font(.system(.caption, design: .monospaced))
                        .listRowBackground(bgColor)
                } header: {
                    Text("EVENT LOG")
                        .foregroundColor(accentColor)
                        .font(.system(.caption, design: .monospaced))
                }

                ForEach(provider.recentEvents.reversed()) { event in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(dateFormatter.string(from: event.timestamp))
                                .foregroundColor(.gray)
                                .font(.system(.caption, design: .monospaced))
                            Spacer()
                        }
                        Text(event.eventName)
                            .foregroundColor(.white)
                            .font(.system(.subheadline, design: .monospaced))
                            .bold()
                        if !event.propertiesSummary.isEmpty {
                            Text(event.propertiesSummary)
                                .foregroundColor(Color(red: 0.6, green: 0.8, blue: 0.6))
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(3)
                        }
                    }
                    .padding(.vertical, 2)
                    .listRowBackground(bgColor)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(bgColor)
    }
}
