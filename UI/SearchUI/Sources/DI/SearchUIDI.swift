import SwiftUI
import SearchUI
import Product
import Search
import SnackbarUI
import WishlistUIDI
import BagUIDI

public struct SearchUIDI {
    private let navigation: SearchNavigation
    private let getProducts: GetProductsUseCase
    private let getCategories: GetCategoriesUseCase
    private let getSearchHistory: GetSearchHistoryUseCase
    private let recordSearch: RecordSearchUseCase
    private let clearSearchHistory: ClearSearchHistoryUseCase
    private let snackbarPresenter: SnackbarPresenting
    private let wishlistUIDI: WishlistUIDI
    private let bagUIDI: BagUIDI

    public init(
        navigation: SearchNavigation,
        getProducts: GetProductsUseCase,
        getCategories: GetCategoriesUseCase,
        getSearchHistory: GetSearchHistoryUseCase,
        recordSearch: RecordSearchUseCase,
        clearSearchHistory: ClearSearchHistoryUseCase,
        snackbarPresenter: SnackbarPresenting,
        wishlistUIDI: WishlistUIDI,
        bagUIDI: BagUIDI
    ) {
        self.navigation = navigation
        self.getProducts = getProducts
        self.getCategories = getCategories
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
                getCategories: getCategories,
                recordSearch: recordSearch,
                snackbar: snackbarPresenter
            ),
            searchingViewModel: SearchingViewModel(
                getSearchHistory: getSearchHistory,
                clearSearchHistory: clearSearchHistory,
                getProducts: getProducts
            ),
            navigation: navigation
        )
    }

    @MainActor
    public func catalogResultsView(filter: CatalogFilter) -> some View {
        CatalogResultsView(
            viewModel: CatalogResultsViewModel(
                filter: filter,
                getProducts: getProducts,
                snackbar: snackbarPresenter
            ),
            navigation: navigation,
            wishlistButton: { id in AnyView(wishlistUIDI.button(productId: id)) },
            bagButton: { id in AnyView(bagUIDI.button(productId: id)) }
        )
    }
}
