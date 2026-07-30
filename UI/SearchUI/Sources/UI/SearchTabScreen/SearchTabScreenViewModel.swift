import Foundation
import Product
import SearchHistory
import SnackbarUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class SearchTabScreenViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var isSearchActive: Bool = false
    @Published private(set) var categories: [ProductCategory] = []

    private let browseCategories: BrowseCategoriesUseCase
    private let recordSearch: RecordSearchUseCase
    private let snackbar: SnackbarPresenting

    public init(
        browseCategories: BrowseCategoriesUseCase,
        recordSearch: RecordSearchUseCase,
        snackbar: SnackbarPresenting
    ) {
        self.browseCategories = browseCategories
        self.recordSearch = recordSearch
        self.snackbar = snackbar
    }

    func onAppear() async {
        guard categories.isEmpty else { return }
        await loadCategories()
    }

    private func loadCategories() async {
        switch await browseCategories() {
        case .success(let value):
            categories = value
        case .failure:
            snackbar.show(Snackbar(
                title: "Couldn't Load Categories",
                message: "Check your connection and try again.",
                icon: "wifi.exclamationmark",
                action: .retry { [weak self] in
                    Task { await self?.loadCategories() }
                }
            ))
        }
    }

    func didSubmitSearch(_ term: SearchTerm) {
        Task { await recordSearch(term) }
    }

    func didSelectCategory(_ category: ProductCategory) {
    }
}
