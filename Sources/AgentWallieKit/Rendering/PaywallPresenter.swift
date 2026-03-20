import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Handles presenting paywalls as modal/sheet/fullscreen.
@available(iOS 16.0, *)
public final class PaywallPresenter: @unchecked Sendable {

    public init() {}

    /// Present a paywall schema using the system's presentation mechanism.
    @MainActor
    public func present(
        schema: PaywallSchema,
        resolvedProducts: [ResolvedProductInfo]? = nil,
        onAction: @escaping (TapBehavior, String?) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        #if canImport(UIKit)
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        let paywallView = PaywallView(
            schema: schema,
            resolvedProducts: resolvedProducts,
            onAction: onAction,
            onDismiss: {
                rootVC.presentedViewController?.dismiss(animated: true)
                onDismiss()
            }
        )

        let hostingController = UIHostingController(rootView: paywallView)

        switch schema.settings.presentation {
        case .fullscreen:
            hostingController.modalPresentationStyle = .fullScreen

        case .sheet:
            hostingController.modalPresentationStyle = .pageSheet

        case .modal:
            hostingController.modalPresentationStyle = .formSheet

        case .inline:
            // Inline doesn't use presentation — it's embedded directly.
            // Fall back to sheet for programmatic presentation.
            hostingController.modalPresentationStyle = .pageSheet
        }

        var presenter = rootVC
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        presenter.present(hostingController, animated: true)
        #endif
    }
}
