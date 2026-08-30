import SwiftUI
import SnackbarUI

@MainActor
@Observable
public final class SnackbarPresenter: SnackbarPresenting {
    private static let transition: Animation = .easeInOut(duration: 0.25)

    public private(set) var current: Snackbar?

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

    public func performAction() {
        let action = current?.action
        dismiss()
        action?.handler()
    }
}
