import SwiftUI
import SessionDI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: the composition root. Every
/// concrete type in the app is named in one of its three phases and nowhere else, so swapping one
/// is a change to this folder alone.
///
/// The phases are the layers the architecture already has — `DataAssembler` names the stores and
/// clients, `DomainAssembler` builds the component containers over them, `PresentationAssembler`
/// builds the features from use cases. Each is handed only the phase before it, so the wiring runs
/// one way and no phase can reach forward into the next.
///
/// Seemann & van Deursen, *Dependency Injection* (2019) — Composition Root: still a single
/// location. Three assemblers constructed here in one order are one composition root with its
/// phases named, not three places where composition happens.
///
/// Martin, Ch. 22 — The Clean Architecture: the outermost ring. Nothing inward knows it exists. Not
/// unit tested — it is wiring, with no behaviour of its own.
///
/// Fowler, *Inversion of Control Containers and the Dependency Injection Pattern* (2004) —
/// Dependency Injection, not a Service Locator: collaborators are handed in through initialisers
/// rather than looked up. `Catalog` arrives the same way, which is what lets a demo vary it
/// without this file knowing demos exist.
@MainActor
final class CompositionRoot {
    /// The graph the app runs on. Both catalogs compile whichever way `Demo.isOn` is set, so a
    /// demo cannot rot unnoticed and switching one on is never a matter of uncommenting code.
    static let shared = CompositionRoot(
        catalog: Demo.isOn ? Demo.shopThatChangesItsMind() : .live()
    )

    let data: DataAssembler
    let domain: DomainAssembler
    let presentation: PresentationAssembler

    init(catalog: Catalog, data: DataAssembler = DataAssembler()) {
        let domain = DomainAssembler(data: data, catalog: catalog)

        self.data = data
        self.domain = domain
        self.presentation = PresentationAssembler(domain: domain)
    }

    // MARK: - Root

    func makeMainViewModel() -> MainViewModel {
        MainViewModel(getSession: domain.session.getSessionUseCase)
    }
}
