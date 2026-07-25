import SwiftUI

/// Presents modal content and reports how it ended. A generic building block for any
/// "show a sheet, maybe chain to another, then resume the caller" flow — not tied to
/// authentication or any other specific feature.
@MainActor
public protocol SheetPresenting: AnyObject {
    /// Presents `content`, replacing whatever is currently showing. Chaining straight from
    /// one sheet to the next needs no separate dismiss step first.
    ///
    /// - Parameter onDismiss: fires only when the user ends this sheet — not when a later
    ///   `present` supersedes it, and not when `dismiss()` ends it programmatically. Use it
    ///   to resume a caller waiting on the outcome of the flow.
    func present<Content: View>(onDismiss: (() -> Void)?, @ViewBuilder content: () -> Content)

    /// Ends the current presentation without firing its `onDismiss`, and drops anything
    /// queued behind it.
    func dismiss()
}

public extension SheetPresenting {
    func present<Content: View>(@ViewBuilder content: () -> Content) {
        present(onDismiss: nil, content: content)
    }
}
