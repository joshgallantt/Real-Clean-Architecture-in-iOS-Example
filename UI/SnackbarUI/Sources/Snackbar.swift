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
}

public struct SnackbarAction {
    public let label: String
    public let handler: @MainActor () -> Void

    public init(label: String, handler: @escaping @MainActor () -> Void) {
        self.label = label
        self.handler = handler
    }

    public static func undo(_ handler: @escaping @MainActor () -> Void) -> SnackbarAction {
        SnackbarAction(label: "Undo", handler: handler)
    }

    public static func retry(_ handler: @escaping @MainActor () -> Void) -> SnackbarAction {
        SnackbarAction(label: "Retry", handler: handler)
    }
}
