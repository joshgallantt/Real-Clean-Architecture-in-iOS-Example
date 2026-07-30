import SheetUI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: constructs the concrete
/// presenter behind `SheetPresenting`. Features link the port and never this, so the composition
/// root is the only place that names the implementation.
public struct SheetUIDI {
    public let presenter: SheetPresenter

    @MainActor
    public init() {
        self.presenter = SheetPresenter()
    }
}
