import SwiftUI

/// Presents modal content and reports how it ended. A generic building block for any
/// "show a sheet, maybe chain to another, then resume the caller" flow — not tied to
/// authentication or any other specific feature.
@MainActor
public protocol SheetPresenting: AnyObject {
    /// Presents `content` in place of whatever this coordinator is currently showing, if
    /// anything — chaining straight from one sheet to the next needs no separate dismiss
    /// step first.
    ///
    /// - Parameter onDismiss: fires only if the sheet is dismissed by the user (swipe, or
    ///   any close action that doesn't go through `dismissCurrentSheet()`) — not when a
    ///   later `present`/`dismissCurrentSheet()` call ends it programmatically. Use this to
    ///   resume a caller that's waiting on the outcome (e.g. resolve a suspended action).
    func present<Content: View>(onDismiss: (() -> Void)?, @ViewBuilder content: () -> Content)

    /// Dismisses whatever this coordinator is currently presenting, if anything, without
    /// firing that sheet's `onDismiss`.
    func dismissCurrentSheet()
}
