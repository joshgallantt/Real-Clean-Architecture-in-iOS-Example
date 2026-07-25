/// The port features call to surface a snackbar. Implemented by `SnackbarPresenter`,
/// wired in the composition root and rendered once at the app root.
@MainActor
public protocol SnackbarPresenting: AnyObject {
    func show(_ snackbar: Snackbar)
}
