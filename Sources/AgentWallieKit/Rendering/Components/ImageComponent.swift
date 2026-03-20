import SwiftUI

/// Renders an image component from the paywall schema.
@available(iOS 16.0, *)
struct ImageComponentView: View {
    let data: ImageComponentData
    let theme: PaywallTheme?

    var body: some View {
        AsyncImage(url: URL(string: data.props.src)) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(Color(hex: theme?.surface ?? "#F2F2F7"))
                    .overlay(ProgressView())
                    .frame(maxWidth: .infinity)
                    .aspectRatio(parsedAspectRatio, contentMode: .fit)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(parsedAspectRatio, contentMode: contentMode)
                    .clipped()
            case .failure:
                Rectangle()
                    .fill(Color(hex: theme?.surface ?? "#F2F2F7"))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(Color(hex: theme?.textSecondary ?? "#6B7280"))
                    )
                    .frame(maxWidth: .infinity)
                    .aspectRatio(parsedAspectRatio, contentMode: .fit)
            @unknown default:
                EmptyView()
            }
        }
        .applyOptionalCornerRadius(data.style?.cornerRadius?.doubleValue.map { CGFloat($0) })
        .clipped()
        .modifier(StyleModifier(style: data.style, theme: theme, skipCornerRadius: true))
    }

    private var parsedAspectRatio: CGFloat? {
        guard let ratio = data.props.aspectRatio else { return nil }
        let parts = ratio.split(separator: ":").compactMap { Double($0) }
        guard parts.count == 2, parts[1] > 0 else { return nil }
        return CGFloat(parts[0] / parts[1])
    }

    private var contentMode: ContentMode {
        switch data.props.fit {
        case "contain": return .fit
        case "fill", "cover": return .fill
        default: return .fill
        }
    }
}
