import SwiftUI
import SearchUI
import Product
import Search

public struct SearchUIDI {
    private let navigation: SearchNavigation
    private let getProducts: GetProductsUseCase
    private let getCategories: GetCategoriesUseCase
    private let getSearchHistory: GetSearchHistoryUseCase
    private let recordSearch: RecordSearchUseCase
    private let clearSearchHistory: ClearSearchHistoryUseCase

    public init(
        navigation: SearchNavigation,
        getProducts: GetProductsUseCase,
        getCategories: GetCategoriesUseCase,
        getSearchHistory: GetSearchHistoryUseCase,
        recordSearch: RecordSearchUseCase,
        clearSearchHistory: ClearSearchHistoryUseCase
    ) {
        self.navigation = navigation
        self.getProducts = getProducts
        self.getCategories = getCategories
        self.getSearchHistory = getSearchHistory
        self.recordSearch = recordSearch
        self.clearSearchHistory = clearSearchHistory
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
            navigation: navigation
        )
    }

    @MainActor
    public func categoryResultsView(category: CategorySlug) -> some View {
        CategoryResultsView(
            viewModel: CategoryResultsViewModel(category: category, getProducts: getProducts),
            navigation: navigation
        )
    }
}
