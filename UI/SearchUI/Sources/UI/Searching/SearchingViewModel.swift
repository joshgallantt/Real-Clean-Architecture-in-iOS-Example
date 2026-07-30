import Foundation
import Product
import SearchHistory

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class SearchingViewModel: ObservableObject {
    @Published private(set) var history = SearchHistory()
    @Published private(set) var suggestions: [Product] = []
    @Published private(set) var isSuggesting: Bool = false

    private let getSearchHistory: GetSearchHistoryUseCase
    private let clearSearchHistory: ClearSearchHistoryUseCase
    private let browseCatalog: BrowseCatalogUseCase
    private var searchTask: Task<Void, Never>?

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
        history = await getSearchHistory()
    }

    func queryChanged(_ typed: String) {
        searchTask?.cancel()

        guard let term = SearchTerm(typed) else {
            suggestions = []
            return
        }

        searchTask = Task {
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
        Task {
            await clearSearchHistory()
            history = await getSearchHistory()
        }
    }
}
