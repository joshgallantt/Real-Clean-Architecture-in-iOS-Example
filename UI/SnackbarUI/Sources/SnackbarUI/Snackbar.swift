import Foundation

/// A transient notification shown above the tab bar. The optional `action` is supplied
/// by the caller: Undo carries the inverse operation, Retry re-invokes the failed one.
/// Dismissal is intrinsic (tap or auto-hide) and never involves the caller.
public struct Snackbar {
    public let title: String
    public let message: String
    public let icon: String?
    public let action: SnackbarAction?

    public init(title: String, message: String, icon: String? = nil, action: SnackbarAction? = nil) {
        self.title = title
        self.message = message
        self.icon = icon
        self.action = action
    }

    /// How long this snackbar earns on screen. An actionable one stays longer because the
    /// user has to read it *and* decide, whereas a purely informational one only has to be
    /// read. The rule belongs to the snackbar, not to whatever is displaying it.
    public var displayDuration: Duration {
        action == nil ? .seconds(2) : .seconds(3.5)
    }
}
