import SwiftUI
import SnackbarUI

/// Default `SnackbarPresenting` implementation. Holds the one snackbar on screen and the
/// timer that retires it. Attach `.snackbarHost(_:)` wherever snackbars should appear.
@MainActor
public final class SnackbarPresenter: ObservableObject, SnackbarPresenting {
    private static let transition: Animation = .easeInOut(duration: 0.25)

    @Published public private(set) var current: Snackbar?

    private var hideTask: Task<Void, Never>?

    public init() {}

    public func show(_ snackbar: Snackbar) {
        hideTask?.cancel()

        withAnimation(Self.transition) {
            current = snackbar
        }

        hideTask = Task { [weak self] in
            try? await Task.sleep(for: snackbar.displayDuration)
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }

    public func dismiss() {
        hideTask?.cancel()
        hideTask = nil

        withAnimation(Self.transition) {
            current = nil
        }
    }

    /// Runs the snackbar's action and retires it — the snackbar has served its purpose the
    /// moment the user acts on it.
    public func performAction() {
        let action = current?.action
        dismiss()
        action?.handler()
    }
}
