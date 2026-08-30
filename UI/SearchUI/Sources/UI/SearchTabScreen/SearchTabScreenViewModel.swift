import Foundation
import Product
import SearchHistory
import SnackbarUI

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class SearchTabScreenViewModel {
    /// The work the last interaction started.
    ///
    /// SwiftUI calls a button's action synchronously, so anything that has to be
    /// awaited starts a `Task` and returns. Keeping the handle is what lets a
    /// test wait for that work rather than guess at how long it takes.
    ///
    /// `@ObservationIgnored` because no view body reads it: it exists for the
    /// caller that started the work, not for anything drawn from it.
    @ObservationIgnored public private(set) var inFlight: Task<Void, Never>?
    var query: String = ""
    var isSearchActive: Bool = false
    private(set) var categories: [ProductCategory] = []

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
                title: "Nothing's Loading",
                message: "Check your signal and give it another go.",
                icon: "wifi.exclamationmark",
                action: .retry { [weak self] in
                    self?.inFlight = Task { await self?.loadCategories() }
                }
            ))
        }
    }

    func didSubmitSearch(_ term: SearchTerm) {
        recordSearch(term)
    }

    func didSelectCategory(_ category: ProductCategory) {
    }
}
