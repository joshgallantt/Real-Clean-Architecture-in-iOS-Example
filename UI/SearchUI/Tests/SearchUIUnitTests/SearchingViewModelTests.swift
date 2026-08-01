import Foundation
import Testing
import Product
import SearchHistory
@testable import SearchUI

@MainActor
@Suite("Searching")
struct SearchingViewModelTests {
    private func makeViewModel(
        getSearchHistory: StubGetSearchHistory = StubGetSearchHistory(),
        clearSearchHistory: SpyClearSearchHistory = SpyClearSearchHistory(),
        browseCatalog: StubBrowseCatalog = StubBrowseCatalog()
    ) -> SearchingViewModel {
        SearchingViewModel(
            getSearchHistory: getSearchHistory,
            clearSearchHistory: clearSearchHistory,
            browseCatalog: browseCatalog
        )
    }

    @Test("Appearing shows whatever history is already there")
    func appearingShowsHistory() async {
        let getSearchHistory = StubGetSearchHistory()
        getSearchHistory.history = SearchHistory(terms: [SearchTerm("lipstick")!])
        let viewModel = makeViewModel(getSearchHistory: getSearchHistory)

        await viewModel.onAppear()

        #expect(viewModel.history.terms == [SearchTerm("lipstick")!])
    }

    @Test("A blank query has no suggestions and asks the shop nothing")
    func blankQueryHasNoSuggestions() {
        let browseCatalog = StubBrowseCatalog()
        let viewModel = makeViewModel(browseCatalog: browseCatalog)

        viewModel.queryChanged("   ")

        #expect(viewModel.suggestions.isEmpty)
        #expect(browseCatalog.queries.isEmpty)
    }

    @Test("Typing something searches the catalog for it, after a short pause")
    func typingSearchesAfterAPause() async {
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.result = .success([.fixture(id: 1)])
        let viewModel = makeViewModel(browseCatalog: browseCatalog)

        viewModel.queryChanged("lipstick")
        await waitUntil { !viewModel.suggestions.isEmpty }

        #expect(browseCatalog.queries.map(\.filter) == [.search(SearchTerm("lipstick")!)])
        #expect(viewModel.suggestions.map(\.id) == [pid(1)])
    }

    @Test("Typing again before the pause is up cancels the search that was waiting")
    func retypingCancelsThePendingSearch() async {
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.result = .success([.fixture(id: 1)])
        let viewModel = makeViewModel(browseCatalog: browseCatalog)

        viewModel.queryChanged("lip")
        viewModel.queryChanged("lipstick")
        await waitUntil { !browseCatalog.queries.isEmpty }
        await settle()

        #expect(browseCatalog.queries.map(\.filter) == [.search(SearchTerm("lipstick")!)])
    }

    @Test("Clearing history empties it, both what is stored and what is shown")
    func clearingHistoryEmptiesIt() {
        let getSearchHistory = StubGetSearchHistory()
        getSearchHistory.history = SearchHistory(terms: [SearchTerm("lipstick")!])
        let clearSearchHistory = SpyClearSearchHistory()
        let viewModel = makeViewModel(getSearchHistory: getSearchHistory, clearSearchHistory: clearSearchHistory)

        getSearchHistory.history = SearchHistory()
        viewModel.clearHistory()

        #expect(clearSearchHistory.callCount == 1)
        #expect(viewModel.history.isEmpty)
    }
}
