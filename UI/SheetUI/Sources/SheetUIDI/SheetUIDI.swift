import SheetUI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds this feature's view
/// hierarchy and holds its collaborators.
///
/// Martin, Ch. 10 — Interface Segregation Principle: handed individual use cases, never a whole
/// component container. Injecting the container would be a Service Locator (Fowler, *Inversion of
/// Control Containers and the Dependency Injection Pattern* (2004)) and would blur the boundary the
/// layering exists to enforce.
public struct SheetUIDI {
    public let presenter: SheetPresenter

    @MainActor
    public init() {
        self.presenter = SheetPresenter()
    }
}
