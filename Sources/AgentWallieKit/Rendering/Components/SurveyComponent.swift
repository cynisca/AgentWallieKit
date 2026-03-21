import SwiftUI

/// Renders an inline survey with selectable option buttons.
@available(iOS 16.0, *)
struct SurveyComponentView: View {
    let data: SurveyComponentData
    let theme: PaywallTheme?
    let onAction: (TapBehavior, String?) -> Void

    @State private var selectedOptions: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(data.props.question)
                .font(resolveFont(textStyle: "headline", fontSize: data.style?.fontSize, fontFamily: data.style?.fontFamily, theme: theme))
                .foregroundColor(resolveColor(data.style?.textColor, theme: theme) ?? Color(hex: theme?.textPrimary ?? PaywallTheme.defaultTextPrimary))

            ForEach(Array(data.props.options.enumerated()), id: \.offset) { index, option in
                Button(action: {
                    toggleOption(index)
                }) {
                    HStack {
                        Text(option)
                            .foregroundColor(selectedOptions.contains(index)
                                ? .white
                                : (resolveColor(data.style?.textColor, theme: theme) ?? Color(hex: theme?.textPrimary ?? PaywallTheme.defaultTextPrimary)))
                        Spacer()
                        if selectedOptions.contains(index) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedOptions.contains(index)
                                ? (resolveColor(data.style?.color, theme: theme) ?? Color(hex: theme?.primary ?? PaywallTheme.defaultPrimary))
                                : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(resolveColor(data.style?.borderColor, theme: theme) ?? Color(hex: theme?.textSecondary ?? PaywallTheme.defaultTextSecondary).opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .modifier(StyleModifier(style: data.style, theme: theme))
    }

    private func toggleOption(_ index: Int) {
        if data.props.allowMultiple {
            if selectedOptions.contains(index) {
                selectedOptions.remove(index)
            } else {
                selectedOptions.insert(index)
            }
        } else {
            selectedOptions = [index]
        }
        let selectedAnswers = selectedOptions.sorted().map { data.props.options[$0] }.joined(separator: ",")
        onAction(.customAction, selectedAnswers)
    }
}
