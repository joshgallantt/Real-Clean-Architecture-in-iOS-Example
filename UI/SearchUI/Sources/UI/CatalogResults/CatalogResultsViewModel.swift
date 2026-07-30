import Foundation
import Product
import SnackbarUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class CatalogResultsViewModel: ObservableObject {
    let filter: CatalogFilter
    @Published private(set) var results: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false

    private let browseCatalog: BrowseCatalogUseCase
    private let snackbar: SnackbarPresenting

    private let pageSize = 30
    private var page = 0
    private var hasMore = true

    public init(filter: CatalogFilter, browseCatalog: BrowseCatalogUseCase, snackbar: SnackbarPresenting) {
        self.filter = filter
        self.browseCatalog = browseCatalog
        self.snackbar = snackbar
    }

    var title: String {
        switch filter {
        case .all: "All Products"
        case .search(let term): term.text
        case .category(let category): category.name
        }
    }

    var emptySearchText: String? {
        guard case .search(let term) = filter else { return nil }
        return term.text
    }

    func onAppear() async {
        guard results.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

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

        switch await browseCatalog(matching: CatalogQuery(filter: filter, page: nextPage, pageSize: pageSize)) {
        case .success(let value):
            results = reset ? value : results + value
            page = nextPage
            hasMore = value.count == pageSize
        case .failure:
            snackbar.show(Snackbar(
                title: "Couldn't Load Products",
                message: "Check your connection and try again.",
                icon: "wifi.exclamationmark",
                action: .retry { [weak self] in
                    Task { await self?.load(reset: reset) }
                }
            ))
        }
    }

    func didSelect(_ product: Product) {
    }
}
