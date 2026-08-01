import Foundation
import Testing
import Product
@testable import SearchUI

@MainActor
@Suite("Catalog results")
struct CatalogResultsViewModelTests {
    private func makeViewModel(
        filter: CatalogFilter = .all,
        browseCatalog: StubBrowseCatalog = StubBrowseCatalog(),
        snackbar: SpySnackbarPresenter = SpySnackbarPresenter()
    ) -> CatalogResultsViewModel {
        CatalogResultsViewModel(filter: filter, browseCatalog: browseCatalog, snackbar: snackbar)
    }

    @Test("Browsing everything is titled for that, not for the absence of a category")
    func titleForAll() {
        #expect(makeViewModel(filter: .all).title == "All Products")
    }

    @Test("A search is titled by what was searched for")
    func titleForSearch() {
        let viewModel = makeViewModel(filter: .search(SearchTerm("lipstick")!))
        #expect(viewModel.title == "lipstick")
        #expect(viewModel.emptySearchText == "lipstick")
    }

    @Test("A category is titled by its own name, and has no search text to fall back on")
    func titleForCategory() {
        let category = ProductCategory(id: CategoryID(rawValue: "beauty"), name: "Beauty")
        let viewModel = makeViewModel(filter: .category(category))
        #expect(viewModel.title == "Beauty")
        #expect(viewModel.emptySearchText == nil)
    }

    @Test("Appearing loads the first page for the filter it was given")
    func appearingLoadsTheFirstPage() async {
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.result = .success([.fixture(id: 1)])
        let category = ProductCategory(id: CategoryID(rawValue: "beauty"), name: "Beauty")
        let viewModel = makeViewModel(filter: .category(category), browseCatalog: browseCatalog)

        await viewModel.onAppear()

        #expect(viewModel.results.map(\.id) == [pid(1)])
        #expect(browseCatalog.queries.map(\.filter) == [.category(category)])
        #expect(browseCatalog.queries.map(\.page) == [0])
    }

    @Test("Appearing again once something has already loaded loads nothing more")
    func appearingAgainLoadsNothingMore() async {
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.result = .success([.fixture(id: 1)])
        let viewModel = makeViewModel(browseCatalog: browseCatalog)
        await viewModel.onAppear()

        await viewModel.onAppear()

        #expect(browseCatalog.queries.count == 1)
    }

    @Test("Loading more asks for the next page and adds to what is already shown")
    func loadingMoreAsksForTheNextPage() async {
        let browseCatalog = StubBrowseCatalog()
        let fullFirstPage = (1...30).map { Product.fixture(id: $0) }
        browseCatalog.result = .success(fullFirstPage)
        let viewModel = makeViewModel(browseCatalog: browseCatalog)
        await viewModel.onAppear()
        browseCatalog.result = .success([.fixture(id: 31)])

        await viewModel.loadMore()

        #expect(browseCatalog.queries.map(\.page) == [0, 1])
        #expect(viewModel.results.count == 31)
        #expect(viewModel.results.last?.id == pid(31))
    }

    @Test("A page that comes back short of a full page is the last one, so there is no more to load")
    func aShortPageMeansNoMore() async {
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.result = .success([.fixture(id: 1)])
        let viewModel = makeViewModel(browseCatalog: browseCatalog)
        await viewModel.onAppear()

        await viewModel.loadMore()

        #expect(browseCatalog.queries.count == 1)
    }

    @Test("A shop that cannot be reached offers to try again")
    func failureOffersRetry() async {
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.result = .failure(.unavailable)
        let snackbar = SpySnackbarPresenter()
        let viewModel = makeViewModel(browseCatalog: browseCatalog, snackbar: snackbar)

        await viewModel.onAppear()

        #expect(viewModel.results.isEmpty)
        #expect(snackbar.shown.first?.title == "Nothing's Loading")
    }
}
