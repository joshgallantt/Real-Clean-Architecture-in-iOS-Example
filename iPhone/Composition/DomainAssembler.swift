import Foundation
import BagDI
import HomeDI
import OrderDI
import SearchHistoryDI
import SessionDI
import SettingsDI
import StockAlertDI
import WishlistDI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: the second phase. Each
/// component container is handed the data sources it cannot invent — or, where it owns no storage,
/// the use cases it composes — and hands back use case protocols; the repositories never escape
/// their packages.
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
    let home: HomeDI
    let searchHistory: SearchHistoryDI
    let wishlist: WishlistDI
    let bag: BagDI
    let settings: SettingsDI
    let stockAlerts: StockAlertDI
    let orders: OrderDI

    init(data: DataAssembler, catalog: Catalog) {
        self.catalog = catalog

        /// The one component here with no store of its own: Home derives a feed from the catalog
        /// rather than keeping one, so it is built from use cases alone.
        home = HomeDI(
            browseCatalog: catalog.browseCatalog,
            browseCategories: catalog.browseCategories
        )

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
            lookUpProducts: catalog.lookUpProducts,
            store: data.bagStore
        )
        settings = SettingsDI(
            getSession: session.getSessionUseCase,
            observeSession: session.observeSessionUseCase,
            store: data.settingsStore
        )
        stockAlerts = StockAlertDI(
            getSession: session.getSessionUseCase,
            observeSession: session.observeSessionUseCase,
            lookUpProducts: catalog.lookUpProducts,
            store: data.stockAlertStore
        )
        orders = OrderDI(
            getSession: session.getSessionUseCase,
            observeSession: session.observeSessionUseCase,
            store: data.orderStore,
            payment: data.paymentClient
        )
    }
}
