import SwiftUI
import SheetUI

/// Default `SheetPresenting` implementation. Attach `.sheetHost(_:)` wherever in the view
/// hierarchy makes sense to present from — it doesn't have to be the app root.
///
/// Only ever one sheet is on screen at a time. Chaining (`present` while something is
/// already up) queues the successor and lets the current one finish dismissing first, so
/// SwiftUI sees a clean dismiss/present pair and the two presentations' outcomes can never
/// be confused for one another.
@MainActor
public final class SheetPresenter: ObservableObject, SheetPresenting {
    /// Settable within the module so the host can clear it when the user swipes a sheet
    /// away; `sheetDidDismiss()` is what turns that into an outcome. Features drive this
    /// through `present`/`dismiss` only.
    @Published var presentation: SheetPresentation?

    /// The handler belonging to what is on screen right now. Cleared the moment that sheet
    /// is superseded or dismissed programmatically, which is what makes those two cases
    /// silent.
    private var dismissalHandler: (() -> Void)?
    private var queued: SheetPresentation?

    public init() {}

    public func present<Content: View>(onDismiss: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        let next = SheetPresentation(content: AnyView(content()), onDismiss: onDismiss)

        guard presentation != nil else {
            show(next)
            return
        }

        queued = next
        dismissalHandler = nil
        presentation = nil
    }

    public func dismiss() {
        queued = nil
        dismissalHandler = nil
        presentation = nil
    }

    /// Called by the host's `.sheet(item:onDismiss:)` whenever a presentation ends, however
    /// it ended.
    func sheetDidDismiss() {
        let handler = dismissalHandler
        dismissalHandler = nil

        if let next = queued {
            queued = nil
            show(next)
        }

        handler?()
    }

    private func show(_ next: SheetPresentation) {
        presentation = next
        dismissalHandler = next.onDismiss
    }
}
