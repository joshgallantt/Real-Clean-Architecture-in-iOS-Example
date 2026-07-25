/// The port features call to surface a snackbar. Deliberately one method: a feature says
/// what happened, and has no say in how long it shows, where it sits, or how it goes away.
@MainActor
public protocol SnackbarPresenting: AnyObject {
    func show(_ snackbar: Snackbar)
}
