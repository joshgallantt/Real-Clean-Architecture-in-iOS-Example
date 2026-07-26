import SwiftUI
import SearchUI
import Product
import Search
import WishlistUIDI
import BagUIDI

public struct SearchUIDI {
    private let navigation: SearchNavigation
    private let getProducts: GetProductsUseCase
    private let getCategories: GetCategoriesUseCase
    private let getSearchHistory: GetSearchHistoryUseCase
    private let recordSearch: RecordSearchUseCase
    private let clearSearchHistory: ClearSearchHistoryUseCase
    private let wishlistUIDI: WishlistUIDI
    private let bagUIDI: BagUIDI

    public init(
        navigation: SearchNavigation,
        getProducts: GetProductsUseCase,
        getCategories: GetCategoriesUseCase,
        getSearchHistory: GetSearchHistoryUseCase,
        recordSearch: RecordSearchUseCase,
        clearSearchHistory: ClearSearchHistoryUseCase,
        wishlistUIDI: WishlistUIDI,
        bagUIDI: BagUIDI
    ) {
        self.navigation = navigation
        self.getProducts = getProducts
        self.getCategories = getCategories
        self.getSearchHistory = getSearchHistory
        self.recordSearch = recordSearch
        self.clearSearchHistory = clearSearchHistory
        self.wishlistUIDI = wishlistUIDI
        self.bagUIDI = bagUIDI
    }

    @MainActor
    public func mainView() -> some View {
        SearchTabScreenView(
            viewModel: SearchTabScreenViewModel(getCategories: getCategories),
            searchingViewModel: SearchingViewModel(
                getSearchHistory: getSearchHistory,
                clearSearchHistory: clearSearchHistory,
                getProducts: getProducts
            ),
            navigation: navigation
        )
    }

    @MainActor
    public func searchResultsView(query: String) -> some View {
        SearchResultsView(
            viewModel: SearchResultsViewModel(query: query, getProducts: getProducts, recordSearch: recordSearch),
            navigation: navigation,
            wishlistButton: { id in AnyView(wishlistUIDI.button(productId: id)) },
            bagButton: { id in AnyView(bagUIDI.button(productId: id)) }
        )
    }

    @MainActor
    public func categoryResultsView(category: CategorySlug) -> some View {
        CategoryResultsView(
            viewModel: CategoryResultsViewModel(category: category, getProducts: getProducts),
            navigation: navigation,
            wishlistButton: { id in AnyView(wishlistUIDI.button(productId: id)) },
            bagButton: { id in AnyView(bagUIDI.button(productId: id)) }
        )
    }
}
