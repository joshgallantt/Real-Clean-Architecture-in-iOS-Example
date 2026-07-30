import SwiftUI
import SearchUI
import Product
import SearchHistory
import SnackbarUI
import WishlistUIDI
import BagUIDI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds this feature's view
/// hierarchy and holds its collaborators.
///
/// Martin, Ch. 10 — Interface Segregation Principle: handed individual use cases, never a whole
/// component container. Injecting the container would be a Service Locator (Fowler, *Inversion of
/// Control Containers and the Dependency Injection Pattern* (2004)) and would blur the boundary the
/// layering exists to enforce.
public struct SearchUIDI {
    private let navigation: SearchNavigation
    private let browseCatalog: BrowseCatalogUseCase
    private let browseCategories: BrowseCategoriesUseCase
    private let getSearchHistory: GetSearchHistoryUseCase
    private let recordSearch: RecordSearchUseCase
    private let clearSearchHistory: ClearSearchHistoryUseCase
    private let snackbarPresenter: SnackbarPresenting
    private let wishlistUIDI: WishlistUIDI
    private let bagUIDI: BagUIDI

    public init(
        navigation: SearchNavigation,
        browseCatalog: BrowseCatalogUseCase,
        browseCategories: BrowseCategoriesUseCase,
        getSearchHistory: GetSearchHistoryUseCase,
        recordSearch: RecordSearchUseCase,
        clearSearchHistory: ClearSearchHistoryUseCase,
        snackbarPresenter: SnackbarPresenting,
        wishlistUIDI: WishlistUIDI,
        bagUIDI: BagUIDI
    ) {
        self.navigation = navigation
        self.browseCatalog = browseCatalog
        self.browseCategories = browseCategories
        self.getSearchHistory = getSearchHistory
        self.recordSearch = recordSearch
        self.clearSearchHistory = clearSearchHistory
        self.snackbarPresenter = snackbarPresenter
        self.wishlistUIDI = wishlistUIDI
        self.bagUIDI = bagUIDI
    }

    @MainActor
    public func mainView() -> some View {
        SearchTabScreenView(
            viewModel: SearchTabScreenViewModel(
                browseCategories: browseCategories,
                recordSearch: recordSearch,
                snackbar: snackbarPresenter
            ),
            searchingViewModel: SearchingViewModel(
                getSearchHistory: getSearchHistory,
                clearSearchHistory: clearSearchHistory,
                browseCatalog: browseCatalog
            ),
            navigation: navigation
        )
    }

    @MainActor
    public func catalogResultsView(filter: CatalogFilter) -> some View {
        CatalogResultsView(
            viewModel: CatalogResultsViewModel(
                filter: filter,
                browseCatalog: browseCatalog,
                snackbar: snackbarPresenter
            ),
            navigation: navigation,
            wishlistButton: { id in AnyView(wishlistUIDI.button(productId: id)) },
            bagButton: { product in AnyView(bagUIDI.button(product: product)) }
        )
    }
}
