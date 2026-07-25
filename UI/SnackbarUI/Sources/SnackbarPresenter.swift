import SwiftUI

@MainActor
public final class SnackbarPresenter: ObservableObject, SnackbarPresenting {
    @Published public private(set) var current: Snackbar?

    private var hideTask: Task<Void, Never>?
    private var generation = 0
    private let displayDuration: TimeInterval
    private let actionDisplayDuration: TimeInterval

    public init(
        displayDuration: TimeInterval = 2,
        actionDisplayDuration: TimeInterval = 3.5
    ) {
        self.displayDuration = displayDuration
        self.actionDisplayDuration = actionDisplayDuration
    }

    public func show(_ snackbar: Snackbar) {
        hideTask?.cancel()
        generation += 1
        let shown = generation

        withAnimation(.easeInOut(duration: 0.25)) {
            current = snackbar
        }

        // Give the user longer to react when there is an action to take.
        let duration = snackbar.action == nil ? displayDuration : actionDisplayDuration
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled, self?.generation == shown else { return }
            self?.dismiss()
        }
    }

    public func dismiss() {
        hideTask?.cancel()
        hideTask = nil
        withAnimation(.easeInOut(duration: 0.25)) {
            current = nil
        }
    }

    public func performAction() {
        let action = current?.action
        dismiss()
        action?.handler()
    }
}
