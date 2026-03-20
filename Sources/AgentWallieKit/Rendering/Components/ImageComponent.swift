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
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(parsedAspectRatio, contentMode: .fit)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .clipped()
            case .failure:
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            @unknown default:
                EmptyView()
            }
        }
        .modifier(StyleModifier(style: data.style))
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
