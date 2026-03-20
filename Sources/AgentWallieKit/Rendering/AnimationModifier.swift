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

    func body(content: Content) -> some View {
        guard let animation = animation else {
            return AnyView(content)
        }

        switch animation.type {
        case AnimationTypeValue.fadeIn:
            return AnyView(
                content
                    .opacity(hasAppeared ? 1 : 0)
                    .onAppear { triggerAnimation() }
            )

        case AnimationTypeValue.slideUp:
            return AnyView(
                content
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 30)
                    .onAppear { triggerAnimation() }
            )

        case AnimationTypeValue.slideInLeft:
            return AnyView(
                content
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(x: hasAppeared ? 0 : -30)
                    .onAppear { triggerAnimation() }
            )

        case AnimationTypeValue.scaleUp:
            return AnyView(
                content
                    .opacity(hasAppeared ? 1 : 0)
                    .scaleEffect(hasAppeared ? 1 : 0.8)
                    .onAppear { triggerAnimation() }
            )

        case AnimationTypeValue.bounce:
            return AnyView(
                content
                    .scaleEffect(hasAppeared ? 1 : 0.8)
                    .onAppear { triggerBounce() }
            )

        case AnimationTypeValue.pulse:
            return AnyView(
                content
                    .opacity(pulseValue ? 1.0 : 0.6)
                    .onAppear { startPulse() }
            )

        case AnimationTypeValue.shake:
            return AnyView(
                content
                    .offset(x: shakeOffset)
                    .onAppear { startShake() }
            )

        default:
            return AnyView(content)
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

    private func startPulse() {
        // Start after delay, then repeat forever
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                pulseValue = true
            }
        }
    }

    private func startShake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Rapid horizontal oscillation
            let shakeDuration = duration / 6
            withAnimation(.easeInOut(duration: shakeDuration).repeatCount(6, autoreverses: true)) {
                shakeOffset = 8
            }
            // Reset after shake completes
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation(.easeOut(duration: shakeDuration)) {
                    shakeOffset = 0
                }
            }
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
