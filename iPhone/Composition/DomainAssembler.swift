import Foundation
import BagDI
import SearchHistoryDI
import SessionDI
import StockAlertDI
import WishlistDI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: the second phase. Each
/// component container is handed the data sources it cannot invent and hands back use case
/// protocols; the repositories never escape their packages.
///
/// Fowler, *Inversion of Control Containers and the Dependency Injection Pattern* (2004) —
/// Dependency Injection: every collaborator arrives through an initialiser. Nothing here looks
/// anything up, and nothing here can reach the presentation phase that comes after it.
///
/// `Catalog` is passed in rather than built, because a demo substitutes a whole catalog of
/// decorated use cases — a domain-level substitution, not a choice of backend, so it does not
/// belong to `DataAssembler`. See `DemoCompositionRoot`.
@MainActor
struct DomainAssembler {
    let session: SessionDI
    let catalog: Catalog
    let searchHistory: SearchHistoryDI
    let wishlist: WishlistDI
    let bag: BagDI
    let stockAlerts: StockAlertDI

    init(data: DataAssembler, catalog: Catalog) {
        self.catalog = catalog

        let session = SessionDI(
            sessionStore: data.sessionStore,
            authClient: data.authClient
        )
        self.session = session

        searchHistory = SearchHistoryDI(
            store: data.searchHistoryStore,
            getSession: session.getSessionUseCase,
            observeSession: session.observeSessionUseCase
        )
        wishlist = WishlistDI(
            getSession: session.getSessionUseCase,
            observeSession: session.observeSessionUseCase,
            store: data.wishlistStore
        )
        bag = BagDI(
            getSession: session.getSessionUseCase,
            observeSession: session.observeSessionUseCase,
            store: data.bagStore
        )
        stockAlerts = StockAlertDI(
            getSession: session.getSessionUseCase,
            observeSession: session.observeSessionUseCase,
            store: data.stockAlertStore
        )
    }
}
