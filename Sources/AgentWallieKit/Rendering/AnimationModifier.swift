import SwiftUI

// MARK: - Animation Type Constants

/// Known animation type string values matching the JSON schema.
enum AnimationTypeValue {
    static let fadeIn = "fade_in"
    static let slideUp = "slide_up"
    static let slideInLeft = "slide_in_left"
    static let scaleUp = "scale_up"
    static let bounce = "bounce"
    static let pulse = "pulse"
    static let shake = "shake"
}

// MARK: - Animation Modifier

/// A ViewModifier that applies entrance animations to components based on a ComponentAnimation definition.
///
/// One-shot animations (fade_in, slide_up, slide_in_left, scale_up, bounce) trigger on appear.
/// Repeating animations (pulse, shake) loop continuously.
@available(iOS 16.0, *)
struct AnimationModifier: ViewModifier {
    let animation: ComponentAnimation?

    @State private var hasAppeared = false
    @State private var pulseValue = false
    @State private var shakeOffset: CGFloat = 0

    /// Default duration in seconds when none is specified.
    static let defaultDurationSeconds: Double = 0.3
    /// Default delay in seconds when none is specified.
    static let defaultDelaySeconds: Double = 0.0

    private var duration: Double {
        guard let ms = animation?.durationMs else { return Self.defaultDurationSeconds }
        return Double(ms) / 1000.0
    }

    private var delay: Double {
        guard let ms = animation?.delayMs else { return Self.defaultDelaySeconds }
        return Double(ms) / 1000.0
    }

    private var opacity: Double {
        guard let animation = animation else { return 1 }
        switch animation.type {
        case AnimationTypeValue.fadeIn, AnimationTypeValue.slideUp, AnimationTypeValue.slideInLeft, AnimationTypeValue.scaleUp:
            return hasAppeared ? 1 : 0
        case AnimationTypeValue.pulse:
            return pulseValue ? 1.0 : 0.6
        default:
            return 1
        }
    }

    private var xOffset: CGFloat {
        guard let animation = animation else { return 0 }
        switch animation.type {
        case AnimationTypeValue.slideInLeft:
            return hasAppeared ? 0 : -30
        case AnimationTypeValue.shake:
            return shakeOffset
        default:
            return 0
        }
    }

    private var yOffset: CGFloat {
        guard let animation = animation else { return 0 }
        switch animation.type {
        case AnimationTypeValue.slideUp:
            return hasAppeared ? 0 : 30
        default:
            return 0
        }
    }

    private var scale: CGFloat {
        guard let animation = animation else { return 1 }
        switch animation.type {
        case AnimationTypeValue.scaleUp, AnimationTypeValue.bounce:
            return hasAppeared ? 1 : 0.8
        default:
            return 1
        }
    }

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .offset(x: xOffset, y: yOffset)
            .scaleEffect(scale)
            .task {
                guard let animation = animation else { return }
                switch animation.type {
                case AnimationTypeValue.fadeIn, AnimationTypeValue.slideUp,
                     AnimationTypeValue.slideInLeft, AnimationTypeValue.scaleUp:
                    triggerAnimation()
                case AnimationTypeValue.bounce:
                    triggerBounce()
                case AnimationTypeValue.pulse:
                    await startPulse()
                case AnimationTypeValue.shake:
                    await startShake()
                default:
                    break
                }
            }
    }

    // MARK: - Animation Triggers

    private func triggerAnimation() {
        withAnimation(.easeOut(duration: duration).delay(delay)) {
            hasAppeared = true
        }
    }

    private func triggerBounce() {
        withAnimation(.spring(response: duration, dampingFraction: 0.5).delay(delay)) {
            hasAppeared = true
        }
    }

    private func startPulse() async {
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        guard !Task.isCancelled else { return }
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            pulseValue = true
        }
    }

    private func startShake() async {
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        guard !Task.isCancelled else { return }
        let shakeDuration = duration / 6
        withAnimation(.easeInOut(duration: shakeDuration).repeatCount(6, autoreverses: true)) {
            shakeOffset = 8
        }
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: shakeDuration)) {
            shakeOffset = 0
        }
    }
}

// MARK: - View Extension

@available(iOS 16.0, *)
extension View {
    /// Apply an optional entrance animation to this view.
    func animateEntrance(_ animation: ComponentAnimation?) -> some View {
        self.modifier(AnimationModifier(animation: animation))
    }
}
