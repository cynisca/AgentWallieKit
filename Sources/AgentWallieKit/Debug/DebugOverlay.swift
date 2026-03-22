import SwiftUI

/// Main debug overlay view with tab-based sections.
@available(iOS 16.0, *)
struct DebugOverlay: View {
    @ObservedObject var provider: DebugDataProvider
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: DebugTab = .status

    /// Closure for placement dry evaluation.
    var onEvaluatePlacement: ((String) -> String)?

    private let bgColor = Color(red: 0.1, green: 0.1, blue: 0.18)
    private let accentColor = Color(red: 0.38, green: 0.47, blue: 1.0)

    enum DebugTab: String, CaseIterable {
        case status = "Status"
        case user = "User"
        case products = "Products"
        case placement = "Placement"
        case events = "Events"
        case assignments = "Assignments"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(DebugTab.allCases, id: \.self) { tab in
                            Button {
                                selectedTab = tab
                            } label: {
                                Text(tab.rawValue)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(selectedTab == tab ? .white : .gray)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedTab == tab
                                        ? accentColor.opacity(0.3)
                                        : Color.clear
                                    )
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(bgColor)

                // Content
                Group {
                    switch selectedTab {
                    case .status:
                        DebugStatusView(provider: provider)
                    case .user:
                        DebugUserView(provider: provider)
                    case .products:
                        DebugProductsView(provider: provider)
                    case .placement:
                        DebugPlacementView(provider: provider, onEvaluate: onEvaluatePlacement)
                    case .events:
                        DebugEventLogView(provider: provider)
                    case .assignments:
                        DebugAssignmentsView(provider: provider)
                    }
                }
            }
            .background(bgColor)
            .navigationTitle("AgentWallie Debugger")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    closeButton
                }
                #else
                ToolbarItem(placement: .automatic) {
                    closeButton
                }
                #endif
            }
            #if os(iOS)
            .toolbarBackground(bgColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
        }
        .preferredColorScheme(.dark)
    }

    private var closeButton: some View {
        Button("Close") {
            dismiss()
        }
        .foregroundColor(accentColor)
        .font(.system(.body, design: .monospaced))
    }
}
