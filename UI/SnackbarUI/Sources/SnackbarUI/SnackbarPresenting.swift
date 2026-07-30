@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle; Fowler, *PoEAA*
/// (2002) — Separated Interface: a feature asks for the effect it wants without depending on
/// whatever presents it.
public protocol SnackbarPresenting: AnyObject {
    func show(_ snackbar: Snackbar)
}
