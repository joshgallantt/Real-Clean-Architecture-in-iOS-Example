import Combine
import Foundation
import Product
import SnackbarUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing.
///
/// Martin, Ch. 7 — Single Responsibility Principle: one job, done once — a list of product ids the
/// shopper is holding, filled in from the catalog. Both lists on this tab are that. They differ in
/// where the ids come from and in nothing else, so they differ by an argument rather than by a
/// second copy of the paging, caching and hydration below.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is given a stream of ids, not a wishlist
/// and not a set of stock alerts. Neither aggregate reaches this file, which is why one type can
/// serve both without knowing that either exists.
public final class SavedProductsViewModel: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false


    private let pageSize: Int
    private let savedProductIds: () -> AnyPublisher<[ProductID], Never>
    private let lookUpProducts: LookUpProductsUseCase
    private let snackbar: SnackbarPresenting
    private let couldNotLoad: String

    /// Which of them belong on this list, decided by what the shop says about them *now*.
    /// Two lists are drawn from the same set of asks — the ones still sold out, and the ones back —
    /// and which is which is a fact about stock, not something the app has to have been told.
    ///
    /// Nothing at all where a list is everything the shopper holds. That is not the same as a
    /// filter that keeps everything: an unfiltered list can be counted without fetching a single
    /// product, and a filtered one cannot be judged at all until it has.
    private let keeping: (@MainActor (Product) -> Bool)?

    /// Taking the whole list away. It is given the ids rather than deciding anything, so this type
    /// still does not know whether it is showing a wishlist or a set of alerts.
    private let clear: @MainActor ([ProductID]) async -> Void

    private var cancellables = Set<AnyCancellable>()
    private var saved: [ProductID] = []
    private var cache: [ProductID: Product] = [:]
    private var loadedCount: Int
    private var hydrationTask: Task<Void, Never>?

    public init(
        savedProductIds: @escaping () -> AnyPublisher<[ProductID], Never>,
        lookUpProducts: LookUpProductsUseCase,
        snackbar: SnackbarPresenting,
        couldNotLoad: String,
        keeping: (@MainActor (Product) -> Bool)? = nil,
        clear: @escaping @MainActor ([ProductID]) async -> Void = { _ in },
        pageSize: Int = 30
    ) {
        self.savedProductIds = savedProductIds
        self.lookUpProducts = lookUpProducts
        self.snackbar = snackbar
        self.couldNotLoad = couldNotLoad
        self.keeping = keeping
        self.clear = clear
        self.pageSize = pageSize
        self.loadedCount = pageSize
    }

    var isEmpty: Bool { products.isEmpty }

    /// How many belong on this list, which is not how many a carousel shows: a row shows a handful
    /// and the heading still says how many there are altogether.
    ///
    /// A filtered list can only count what it has fetched, because whether something belongs on it
    /// is a fact about the product. Which is why a filtered list fetches the lot rather than paging
    /// — the alert lists are a handful, and a heading that undercounted them would be worse than
    /// the request it saved.
    var savedCount: Int { keeping == nil ? saved.count : products.count }

    /// Everything the shopper would lose. Taken from the list as it is, so clearing the waitlist does
    /// not touch what has come back and clearing Back in Stock does not touch what is still waited
    /// on — they are two lists, and each Clear means its own.
    func didConfirmClear() {
        let losing = products.map(\.id)
        guard !losing.isEmpty else { return }
        Task { await clear(losing) }
    }

    func onAppear() {
        guard cancellables.isEmpty else { return }

        savedProductIds()
            .sink { [weak self] ids in
                self?.savedChanged(ids)
            }
            .store(in: &cancellables)
    }

    func onReachEnd() {
        guard keeping == nil, loadedCount < saved.count, !isLoading, !isLoadingMore else { return }
        loadedCount += pageSize
        hydrate(isPaging: true)
    }

    private func savedChanged(_ ids: [ProductID]) {
        saved = ids

        let held = Set(ids)
        cache = cache.filter { held.contains($0.key) }

        hydrate(isPaging: false)
    }

    private func hydrate(isPaging: Bool) {
        hydrationTask?.cancel()

        let window = keeping == nil ? Array(saved.prefix(loadedCount)) : saved
        let missing = window.filter { cache[$0] == nil }

        guard !missing.isEmpty else {
            isLoading = false
            isLoadingMore = false
            products = showing(window)
            return
        }

        if isPaging {
            isLoadingMore = true
        } else {
            isLoading = true
        }

        hydrationTask = Task { [weak self] in
            guard let self else { return }
            let result = await self.lookUpProducts(ids: missing)
            guard !Task.isCancelled else { return }

            switch result {
            case .success(let fetched):
                for product in fetched {
                    self.cache[product.id] = product
                }


            case .failure:
                self.snackbar.show(Snackbar(
                    title: self.couldNotLoad,
                    message: "Check your connection and try again.",
                    icon: "wifi.exclamationmark",
                    action: .retry { [weak self] in self?.hydrate(isPaging: isPaging) }
                ))
            }

            self.products = self.showing(window)
            self.isLoading = false
            self.isLoadingMore = false
        }
    }

    private func showing(_ window: [ProductID]) -> [Product] {
        let held = window.compactMap { cache[$0] }
        guard let keeping else { return held }
        return held.filter(keeping)
    }
}
