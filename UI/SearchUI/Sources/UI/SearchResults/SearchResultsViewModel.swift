import Foundation
import Product
import Search

@MainActor
public final class SearchResultsViewModel: ObservableObject {
    let query: String
    @Published private(set) var results: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false

    private let getProducts: GetProductsUseCase
    private let recordSearch: RecordSearchUseCase

    private let pageSize = 30
    private var page = 0
    private var hasMore = true

    public init(query: String, getProducts: GetProductsUseCase, recordSearch: RecordSearchUseCase) {
        self.query = query
        self.getProducts = getProducts
        self.recordSearch = recordSearch
    }

    func onAppear() async {
        guard results.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        await recordSearch(query)
        await load(reset: true)
    }

    func loadMore() async {
        guard hasMore, !isLoading, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        await load(reset: false)
    }

    private func load(reset: Bool) async {
        let nextPage = reset ? 0 : page + 1

        if case .success(let value) = await getProducts(matching: .search(query, page: nextPage, pageSize: pageSize)) {
            results = reset ? value : results + value
            page = nextPage
            hasMore = value.count == pageSize
        }
    }

    func didSelect(_ product: Product) {
        // Any non-navigation side effects, e.g. analytics
    }
}
