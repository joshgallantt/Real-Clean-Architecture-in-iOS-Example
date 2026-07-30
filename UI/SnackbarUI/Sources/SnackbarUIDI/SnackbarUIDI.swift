import SnackbarUI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: constructs the concrete
/// presenter behind `SnackbarPresenting`. Features link the port and never this, so the composition
/// root is the only place that names the implementation.
public struct SnackbarUIDI {
    public let presenter: SnackbarPresenter

    @MainActor
    public init() {
        self.presenter = SnackbarPresenter()
    }
}
