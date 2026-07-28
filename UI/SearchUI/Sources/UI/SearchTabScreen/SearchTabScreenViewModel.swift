import Foundation
import Product
import Search
import SnackbarUI

@MainActor
public final class SearchTabScreenViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var isSearchActive: Bool = false
    @Published private(set) var categories: [ProductCategory] = []

    private let getCategories: GetCategoriesUseCase
    private let recordSearch: RecordSearchUseCase
    private let snackbar: SnackbarPresenting

    public init(
        getCategories: GetCategoriesUseCase,
        recordSearch: RecordSearchUseCase,
        snackbar: SnackbarPresenting
    ) {
        self.getCategories = getCategories
        self.recordSearch = recordSearch
        self.snackbar = snackbar
    }

    func onAppear() async {
        guard categories.isEmpty else { return }
        await loadCategories()
    }

    private func loadCategories() async {
        switch await getCategories() {
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

    /// Recorded here because searching is the act being recorded — not a results screen
    /// rendering, which also fires on every back-and-forward revisit.
    func didSubmitSearch(_ query: String) {
        Task { await recordSearch(query) }
    }

    func didSelectCategory(_ category: ProductCategory) {
        // Any non-navigation side effects, e.g. analytics
    }
}
