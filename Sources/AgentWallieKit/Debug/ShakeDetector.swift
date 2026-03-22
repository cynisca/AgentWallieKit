#if canImport(UIKit)
import UIKit

/// Detects shake gestures by swizzling UIWindow's motionEnded method.
/// When a shake is detected and a callback is set, it fires the callback.
@available(iOS 16.0, *)
final class ShakeDetector {
    /// Callback fired on shake gesture. Set by AgentWallie when enableShakeDebugger is true.
    static var onShake: (() -> Void)?

    /// Installs the shake detection by method swizzling UIWindow.
    /// This is called automatically when onShake is first set.
    private static let swizzle: Void = {
        let originalSelector = #selector(UIWindow.motionEnded(_:with:))
        let swizzledSelector = #selector(UIWindow.aw_motionEnded(_:with:))

        guard let originalMethod = class_getInstanceMethod(UIWindow.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIWindow.self, swizzledSelector) else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()

    /// Ensure swizzling is installed.
    static func install() {
        _ = swizzle
    }
}

extension UIWindow {
    @objc func aw_motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        // Call original implementation (swizzled)
        aw_motionEnded(motion, with: event)

        if motion == .motionShake {
            ShakeDetector.onShake?()
        }
    }
}
#endif
