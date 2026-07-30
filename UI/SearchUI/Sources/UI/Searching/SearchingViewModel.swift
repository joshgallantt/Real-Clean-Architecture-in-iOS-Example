import Foundation
import Product
import SearchHistory

@MainActor
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

    /// What the shopper has typed so far. Whether that is a search at all is `SearchTerm`'s
    /// to say, so this does not trim and does not check for blank.
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
