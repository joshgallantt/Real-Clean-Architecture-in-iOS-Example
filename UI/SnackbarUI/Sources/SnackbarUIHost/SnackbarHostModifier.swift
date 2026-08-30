import SwiftUI

private struct SnackbarHostModifier: ViewModifier {
    let presenter: SnackbarPresenter
    let bottomInset: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let snackbar = presenter.current {
                    SnackbarView(
                        snackbar: snackbar,
                        onAction: presenter.performAction,
                        onDismiss: presenter.dismiss
                    )
                    .padding(.bottom, bottomInset)
                    .transition(.opacity)
                }
            }
    }
}

public extension View {
    func snackbarHost(_ presenter: SnackbarPresenter, aboveTabBar bottomInset: CGFloat = 58) -> some View {
        modifier(SnackbarHostModifier(presenter: presenter, bottomInset: bottomInset))
    }
}
