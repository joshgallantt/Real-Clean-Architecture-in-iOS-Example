import Foundation
import Product
import SearchHistory

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class SearchingViewModel {
    /// The work the last interaction started.
    ///
    /// SwiftUI calls a button's action synchronously, so anything that has to be
    /// awaited starts a `Task` and returns. Keeping the handle is what lets a
    /// test wait for that work rather than guess at how long it takes.
    ///
    /// `@ObservationIgnored` because no view body reads it: it exists for the
    /// caller that started the work, not for anything drawn from it.
    @ObservationIgnored public private(set) var inFlight: Task<Void, Never>?
    private(set) var history = SearchHistory()
    private(set) var suggestions: [Product] = []
    private(set) var isSuggesting: Bool = false

    private let getSearchHistory: GetSearchHistoryUseCase
    private let clearSearchHistory: ClearSearchHistoryUseCase
    private let browseCatalog: BrowseCatalogUseCase

    public init(
        getSearchHistory: GetSearchHistoryUseCase,
        clearSearchHistory: ClearSearchHistoryUseCase,
        browseCatalog: BrowseCatalogUseCase
    ) {
        self.getSearchHistory = getSearchHistory
        self.clearSearchHistory = clearSearchHistory
        self.browseCatalog = browseCatalog
    }

    func onAppear() async {
        history = getSearchHistory()
    }

    func queryChanged(_ typed: String) {
        inFlight?.cancel()

        guard let term = SearchTerm(typed) else {
            suggestions = []
            return
        }

        inFlight = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            isSuggesting = true
            defer { isSuggesting = false }

            if case .success(let products) = await browseCatalog(matching: .search(term, page: 0, pageSize: 10)) {
                guard !Task.isCancelled else { return }
                suggestions = products
            }
        }
    }

    func clearHistory() {
        clearSearchHistory()
        history = getSearchHistory()
    }
}
