import SwiftUI

/// Default `SheetPresenting` implementation. Attach `.sheetHost(_:)` wherever in the view
/// hierarchy makes sense to present from — it doesn't have to be the app root.
@MainActor
public final class SheetCoordinator: ObservableObject, SheetPresenting {
    struct Step: Identifiable {
        let id = UUID()
        let content: AnyView
    }

    @Published var step: Step?
    private var pendingDismissCallback: (() -> Void)?

    public init() {}

    public func present<Content: View>(onDismiss: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        pendingDismissCallback = onDismiss
        step = Step(content: AnyView(content()))
    }

    public func dismissCurrentSheet() {
        pendingDismissCallback = nil
        step = nil
    }

    /// Called by the host's `.sheet(item:onDismiss:)` whenever a presentation ends —
    /// whether interactively or because `present`/`dismissCurrentSheet()` set a new step.
    func handleSheetDismissed() {
        guard let callback = pendingDismissCallback else { return }
        pendingDismissCallback = nil
        callback()
    }
}
