import SwiftUI
import SearchUI
import Product
import SearchHistory
import SnackbarUI
import WishlistUIDI
import ProductActionsUIDI
import Tracking
import TrackingUI

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
    private let productActionsUIDI: ProductActionsUIDI
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private let trackEvent: TrackEventUseCase

    public init(
        navigation: SearchNavigation,
        browseCatalog: BrowseCatalogUseCase,
        browseCategories: BrowseCategoriesUseCase,
        getSearchHistory: GetSearchHistoryUseCase,
        recordSearch: RecordSearchUseCase,
        clearSearchHistory: ClearSearchHistoryUseCase,
        snackbarPresenter: SnackbarPresenting,
        wishlistUIDI: WishlistUIDI,
        productActionsUIDI: ProductActionsUIDI,
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase,
        trackEvent: TrackEventUseCase
    ) {
        self.navigation = navigation
        self.browseCatalog = browseCatalog
        self.browseCategories = browseCategories
        self.getSearchHistory = getSearchHistory
        self.recordSearch = recordSearch
        self.clearSearchHistory = clearSearchHistory
        self.snackbarPresenter = snackbarPresenter
        self.wishlistUIDI = wishlistUIDI
        self.productActionsUIDI = productActionsUIDI
        self.trackScreenView = trackScreenView
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
        self.trackEvent = trackEvent
    }

    @MainActor
    public func mainView() -> some View {
        SearchTabScreenView(
            viewModel: SearchTabScreenViewModel(
                browseCategories: browseCategories,
                recordSearch: recordSearch,
                snackbar: snackbarPresenter,
                trackScreenView: trackScreenView,
                trackElementView: trackElementView,
                trackElementInteraction: trackElementInteraction,
                trackEvent: trackEvent
            ),
            searchingViewModel: SearchingViewModel(
                getSearchHistory: getSearchHistory,
                clearSearchHistory: clearSearchHistory,
                browseCatalog: browseCatalog,
                trackElementView: trackElementView,
                trackElementInteraction: trackElementInteraction
            ),
            navigation: navigation
        )
        /// Declared here, above the screen, so the screen's own body — and every row drawn inside
        /// it — reads it.
        .trackingScreen(SearchTrackingPlan.screen)
    }

    @MainActor
    public func catalogResultsView(filter: CatalogFilter) -> some View {
        CatalogResultsView(
            viewModel: CatalogResultsViewModel(
                filter: filter,
                browseCatalog: browseCatalog,
                snackbar: snackbarPresenter,
                trackScreenView: trackScreenView,
                trackElementView: trackElementView,
                trackElementInteraction: trackElementInteraction
            ),
            navigation: navigation,
            wishlistButton: { product in AnyView(wishlistUIDI.button(product: product)) },
            bagButton: { product in AnyView(productActionsUIDI.cardActionButton(product: product)) }
        )
        .trackingScreen(SearchTrackingPlan.resultsScreen)
    }
}
