import SnackbarUI

/// A spy: it presents, and records what it presented.
///
/// Published here because `SnackbarPresenting` belongs to this package, so the
/// stand-in for it does too. Six copies of these few lines were living in the
/// suites that use it.
///
/// Every member is `public` on purpose. A shared module is consumed with a
/// plain `import`, and `@testable` is not a substitute: it lets a caller
/// compile against internal members and then fails at the link step, which is a
/// much more confusing way to find out.
public final class SpySnackbarPresenter: SnackbarPresenting {
    public private(set) var shown: [Snackbar] = []

    public init() {}

    public func show(_ snackbar: Snackbar) {
        shown.append(snackbar)
    }
}
