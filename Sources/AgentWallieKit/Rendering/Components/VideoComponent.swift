import SwiftUI
import AVKit

/// Renders a video player from a URL using AVKit.
@available(iOS 16.0, *)
struct VideoComponentView: View {
    let data: VideoComponentData
    let theme: PaywallTheme?

    @State private var player: AVPlayer?
    @State private var showPoster: Bool = true

    var body: some View {
        Group {
            if let player = player, !showPoster {
                VideoPlayer(player: player)
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .onAppear {
                        if data.props.muted {
                            player.isMuted = true
                        }
                        if data.props.autoplay {
                            player.play()
                        }
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else if let posterURL = data.props.poster, let url = URL(string: posterURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(16.0 / 9.0, contentMode: .fit)
                } placeholder: {
                    videoPlaceholder
                }
                .onTapGesture {
                    initializePlayer()
                    showPoster = false
                }
            } else {
                videoPlaceholder
                    .onTapGesture {
                        initializePlayer()
                        showPoster = false
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .modifier(StyleModifier(style: data.style, theme: theme))
        .onAppear {
            if data.props.autoplay {
                initializePlayer()
                showPoster = false
            }
        }
    }

    private var videoPlaceholder: some View {
        ZStack {
            Rectangle()
                .fill(Color(hex: theme?.surface ?? "#F2F2F7"))
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
            Image(systemName: "play.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: theme?.textSecondary ?? "#6B7280"))
        }
    }

    private func initializePlayer() {
        guard player == nil, let url = URL(string: data.props.src) else { return }
        let avPlayer = AVPlayer(url: url)
        if data.props.muted {
            avPlayer.isMuted = true
        }
        if data.props.loop {
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: avPlayer.currentItem,
                queue: .main
            ) { _ in
                avPlayer.seek(to: .zero)
                avPlayer.play()
            }
        }
        player = avPlayer
    }
}
