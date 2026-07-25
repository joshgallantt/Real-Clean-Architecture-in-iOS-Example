import Foundation
import Product
import Search

@MainActor
public final class SearchingViewModel: ObservableObject {
    @Published private(set) var history: [String] = []
    @Published private(set) var suggestions: [Product] = []
    @Published private(set) var isSuggesting: Bool = false

    private let getSearchHistory: GetSearchHistoryUseCase
    private let clearSearchHistory: ClearSearchHistoryUseCase
    private let getProducts: GetProductsUseCase
    private var searchTask: Task<Void, Never>?

    public init(
        getSearchHistory: GetSearchHistoryUseCase,
        clearSearchHistory: ClearSearchHistoryUseCase,
        getProducts: GetProductsUseCase
    ) {
        self.getSearchHistory = getSearchHistory
        self.clearSearchHistory = clearSearchHistory
        self.getProducts = getProducts
    }

    func onAppear() async {
        history = await getSearchHistory()
    }

    func queryChanged(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        searchTask?.cancel()

        guard !trimmed.isEmpty else {
            suggestions = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            isSuggesting = true
            defer { isSuggesting = false }

            if case .success(let products) = await getProducts(matching: .search(trimmed, page: 0, pageSize: 10)) {
                guard !Task.isCancelled else { return }
                suggestions = products
            }
        }
    }

    func clearHistory() {
        Task {
            await clearSearchHistory()
            history = []
        }
    }
}
