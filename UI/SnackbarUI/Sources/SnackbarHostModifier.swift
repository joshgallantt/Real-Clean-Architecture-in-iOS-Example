import SwiftUI

public struct SnackbarHostModifier: ViewModifier {
    @ObservedObject private var presenter: SnackbarPresenter
    private let bottomInset: CGFloat

    public init(presenter: SnackbarPresenter, bottomInset: CGFloat) {
        self.presenter = presenter
        self.bottomInset = bottomInset
    }

    public func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let snackbar = presenter.current {
                    SnackbarView(
                        snackbar: snackbar,
                        onAction: { presenter.performAction() },
                        onDismiss: { presenter.dismiss() }
                    )
                    .padding(.bottom, bottomInset)
                    .transition(.opacity)
                }
            }
    }
}

public extension View {
    /// Hosts snackbars bottom-aligned, inset so they sit above the tab bar.
    func snackbarHost(_ presenter: SnackbarPresenter, aboveTabBar bottomInset: CGFloat = 58) -> some View {
        modifier(SnackbarHostModifier(presenter: presenter, bottomInset: bottomInset))
    }
}
