import Foundation
import Product
import Search

@MainActor
public final class SearchResultsViewModel: ObservableObject {
    let query: String
    @Published private(set) var results: [Product] = []
    @Published private(set) var isLoading = false

    private let getProducts: GetProductsUseCase
    private let recordSearch: RecordSearchUseCase

    public init(query: String, getProducts: GetProductsUseCase, recordSearch: RecordSearchUseCase) {
        self.query = query
        self.getProducts = getProducts
        self.recordSearch = recordSearch
    }

    func onAppear() async {
        guard results.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        await recordSearch.execute(query)

        if case .success(let value) = await getProducts.execute(matching: .search(query, page: 0, pageSize: 30)) {
            results = value
        }
    }

    func didSelect(_ product: Product) {
        // Any non-navigation side effects, e.g. analytics
    }
}
