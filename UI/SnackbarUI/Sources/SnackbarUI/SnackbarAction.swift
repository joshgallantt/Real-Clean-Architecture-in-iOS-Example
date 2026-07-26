/// The one thing a snackbar offers to do on the user's behalf. `undo`, `retry`, and `view`
/// are the ones that have earned names; anything else supplies its own label.
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

    public static func view(_ handler: @escaping @MainActor () -> Void) -> SnackbarAction {
        SnackbarAction(label: "View", handler: handler)
    }
}
