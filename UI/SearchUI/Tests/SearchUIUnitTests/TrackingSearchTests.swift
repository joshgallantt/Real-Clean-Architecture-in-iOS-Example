import Foundation
import ProductTestSupport
import SearchHistoryTestSupport
import SnackbarUITestSupport
import Testing
import Product
import SearchHistory
import Tracking
import TrackingTestSupport
import TrackingUI
@testable import SearchUI

@MainActor
@Suite("What Search tells the shop")
/// Where each event happened arrives as the context the view read — the screen, or a row's position
/// in one of the lists on it — so these say what Search reports, given where.
struct TrackingSearchTests {
    private let search = "search"
    private let results = "search_results"
    private let screens = SpyTrackScreenViewUseCase()
    private let views = SpyTrackElementViewUseCase()
    private let taps = SpyTrackElementInteractionUseCase()
    private let reported = SpyTrackEventUseCase()
    private let beauty = ProductCategory(id: CategoryID(rawValue: "beauty"), name: "Beauty")
    private let toys = ProductCategory(id: CategoryID(rawValue: "toys"), name: "Toys")
    private let categoriesList = TrackingContext.List(id: "search_categories", name: "Categories")
    private let historyList = TrackingContext.List(id: "search_history", name: "Recent Searches")

    private func tab(browse: SpyBrowseCategoriesUseCase) -> SearchTabScreenViewModel {
        SearchTabScreenViewModel(
            browseCategories: browse,
            recordSearch: SpyRecordSearchUseCase(),
            snackbar: SpySnackbarPresenting(),
            trackScreenView: screens,
            trackElementView: views,
            trackElementInteraction: taps,
            trackEvent: reported
        )
    }

    private func searching() -> SearchingViewModel {
        SearchingViewModel(
            getSearchHistory: StubGetSearchHistoryUseCase(),
            clearSearchHistory: SpyClearSearchHistoryUseCase(),
            browseCatalog: SpyBrowseCatalogUseCase(),
            trackElementView: views,
            trackElementInteraction: taps
        )
    }

    private func catalog(_ filter: CatalogFilter, browse: SpyBrowseCatalogUseCase) -> CatalogResultsViewModel {
        CatalogResultsViewModel(
            filter: filter,
            browseCatalog: browse,
            snackbar: SpySnackbarPresenting(),
            trackScreenView: screens,
            trackElementView: views,
            trackElementInteraction: taps
        )
    }

    // MARK: - The tab

    @Test("The tab coming into view is a view of Search, every time")
    func tabView() {
        let viewModel = tab(browse: SpyBrowseCategoriesUseCase())

        viewModel.didAppear(in: .screen(search))
        viewModel.didAppear(in: .screen(search))

        #expect(screens.events == [.screenViewed(search), .screenViewed(search)])
    }

    @Test("All Products and a category are seen as rows of the categories list, where each sits")
    func categoriesSeen() {
        let viewModel = tab(browse: SpyBrowseCategoriesUseCase())

        viewModel.didSeeAllProducts(in: .list(search, categoriesList, index: 0))
        viewModel.didSee(toys, in: .list(search, categoriesList, index: 2))

        #expect(views.events == [
            .viewed("category", about: .content(id: "all", name: "All Products"), in: .list(search, categoriesList, index: 0)),
            .viewed("category", about: .content(id: "toys", name: "Toys"), in: .list(search, categoriesList, index: 2))
        ])
    }

    @Test("Picking a category is a tap on its row")
    func categoryPicked() {
        let where_ = TrackingContext.list(search, categoriesList, index: 1)

        tab(browse: SpyBrowseCategoriesUseCase()).didSelectCategory(beauty, in: where_)

        #expect(taps.events == [.tapped("category", about: .content(id: "beauty", name: "Beauty"), in: where_)])
    }

    @Test("Submitting a search is a search for what was typed, on the screen it was typed on")
    func submitted() {
        tab(browse: SpyBrowseCategoriesUseCase()).didSubmitSearch(SearchTerm("lipstick")!, in: .screen(search))

        #expect(reported.events == [TrackingEvent(name: .productsSearched, context: .screen(search), items: [], properties: [.query: "lipstick"])])
    }

    @Test("Categories that will not load say so, and the snackbar saying it is seen on the tab")
    func categoriesSnackbar() async {
        let browse = SpyBrowseCategoriesUseCase()
        browse.result = .failure(.unavailable)

        await tab(browse: browse).onAppear(in: .screen(search))

        #expect(views.events == [.viewed("nothing_s_loading", in: .screen(search))])
    }

    // MARK: - Recent searches and suggestions

    @Test("A recent search seen and tapped is a row of the history list, where it sits")
    func recentSearch() {
        let viewModel = searching()
        let where_ = TrackingContext.list(search, historyList, index: 0)

        viewModel.didSee(SearchTerm("lipstick")!, in: where_)
        viewModel.didSelect(SearchTerm("lipstick")!, in: where_)

        #expect(views.events == [.viewed("recent_search", about: .content(id: "lipstick", name: "lipstick"), in: where_)])
        #expect(taps.events == [.tapped("recent_search", about: .content(id: "lipstick", name: "lipstick"), in: where_)])
    }

    @Test("A suggestion is a product, reported in the suggestions list")
    func suggestion() {
        let product = Product.fixture(id: 3)
        let where_ = TrackingContext.list(search, TrackingContext.List(id: "search_suggestions", name: "Suggestions"), index: 1)

        searching().didSelect(product, in: where_)

        #expect(taps.events == [.tapped("suggestion", about: TrackedProduct.item(product), in: where_)])
    }

    @Test("Clearing the history is a tap on the screen")
    func clearHistory() {
        searching().clearHistory(in: .screen(search))

        #expect(taps.events == [.tapped("clear_history", in: .screen(search))])
    }

    // MARK: - Results

    @Test("The results coming into view are a view of the results screen")
    func resultsView() {
        catalog(.all, browse: SpyBrowseCatalogUseCase()).didAppear(in: .screen(results))

        #expect(screens.events == [.screenViewed(results)])
    }

    @Test("Each kind of results is its own list: all of it, a category, or any search")
    func resultLists() {
        #expect(catalog(.all, browse: SpyBrowseCatalogUseCase()).list == TrackingContext.List(id: "search_results_all", name: "All Products"))
        #expect(catalog(.category(beauty), browse: SpyBrowseCatalogUseCase()).list == TrackingContext.List(id: "search_results_beauty", name: "Beauty"))
        #expect(catalog(.search(SearchTerm("lipstick")!), browse: SpyBrowseCatalogUseCase()).list == TrackingContext.List(id: "search_results_search", name: "lipstick"))
    }

    @Test("A card in the results is reported where it was, counting down the whole list")
    func resultCard() {
        let product = Product.fixture(id: 4)
        let where_ = TrackingContext.list(results, TrackingContext.List(id: "search_results_beauty", name: "Beauty"), index: 33)

        catalog(.category(beauty), browse: SpyBrowseCatalogUseCase()).didSelect(product, in: where_)

        #expect(taps.events == [.tapped("product", about: TrackedProduct.item(product), in: where_)])
    }

    @Test("Results that will not load say so, and the snackbar saying it is seen on the results screen")
    func failureSnackbarSeen() async {
        let browse = SpyBrowseCatalogUseCase()
        browse.result = .failure(.unavailable)

        await catalog(.all, browse: browse).onAppear(in: .screen(results))

        #expect(views.events == [.viewed("nothing_s_loading", in: .screen(results))])
    }

    @Test("Only the last card laid out asks for the next page")
    func pagingFromTheLastCard() async {
        let browse = SpyBrowseCatalogUseCase()
        browse.result = .success((1...30).map { .fixture(id: $0) })
        let viewModel = catalog(.all, browse: browse)
        await viewModel.onAppear(in: .screen(results))

        viewModel.didLayOut(.fixture(id: 5), in: .screen(results))
        #expect(browse.queries.count == 1)

        viewModel.didLayOut(.fixture(id: 30), in: .screen(results))
        await viewModel.inFlight?.value
        #expect(browse.queries.count == 2)
    }
}
