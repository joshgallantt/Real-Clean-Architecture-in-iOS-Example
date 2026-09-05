import Foundation
import ProductTestSupport
import SearchHistoryTestSupport
import SnackbarUITestSupport
import Testing
import Product
@testable import SearchUI

@MainActor
@Suite("The search tab")
struct SearchTabScreenViewModelTests {
    private func makeViewModel(
        browseCategories: SpyBrowseCategoriesUseCase = SpyBrowseCategoriesUseCase(),
        recordSearch: SpyRecordSearchUseCase = SpyRecordSearchUseCase(),
        snackbar: SpySnackbarPresenting = SpySnackbarPresenting()
    ) -> SearchTabScreenViewModel {
        SearchTabScreenViewModel(browseCategories: browseCategories, recordSearch: recordSearch, snackbar: snackbar)
    }

    @Test("Appearing loads the categories the shop divides itself into")
    func appearingLoadsCategories() async {
        let category = ProductCategory(id: CategoryID(rawValue: "beauty"), name: "Beauty")
        let browseCategories = SpyBrowseCategoriesUseCase()
        browseCategories.result = .success([category])
        let viewModel = makeViewModel(browseCategories: browseCategories)

        await viewModel.onAppear()

        #expect(viewModel.categories == [category])
    }

    @Test("Appearing again once categories have already loaded asks for them nothing more")
    func appearingAgainLoadsNothingMore() async {
        let browseCategories = SpyBrowseCategoriesUseCase()
        browseCategories.result = .success([ProductCategory(id: CategoryID(rawValue: "beauty"), name: "Beauty")])
        let viewModel = makeViewModel(browseCategories: browseCategories)
        await viewModel.onAppear()

        await viewModel.onAppear()

        #expect(browseCategories.callCount == 1)
    }

    @Test("A shop that cannot be reached offers to try again")
    func failureOffersRetry() async {
        let browseCategories = SpyBrowseCategoriesUseCase()
        browseCategories.result = .failure(.unavailable)
        let snackbar = SpySnackbarPresenting()
        let viewModel = makeViewModel(browseCategories: browseCategories, snackbar: snackbar)

        await viewModel.onAppear()

        #expect(viewModel.categories.isEmpty)
        #expect(snackbar.shown.first?.title == "Nothing's Loading")
    }

    @Test("Submitting a search records it, exactly as it was typed")
    func submittingRecordsTheSearch() {
        let recordSearch = SpyRecordSearchUseCase()
        let viewModel = makeViewModel(recordSearch: recordSearch)

        viewModel.didSubmitSearch(SearchTerm("lipstick")!)

        #expect(recordSearch.recorded == [SearchTerm("lipstick")!])
    }
}
