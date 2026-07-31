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

    /// Whether anything on this list has been stopped. Not *which*: the shop says so by no longer
    /// answering about them, so there is no name and no picture to show.
    @Published private(set) var somethingHasBeenDiscontinued = false

    private let pageSize: Int
    private let savedProductIds: () -> AnyPublisher<[ProductID], Never>
    private let lookUpProducts: LookUpProductsUseCase
    private let snackbar: SnackbarPresenting
    private let couldNotLoad: String

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
        pageSize: Int = 30
    ) {
        self.savedProductIds = savedProductIds
        self.lookUpProducts = lookUpProducts
        self.snackbar = snackbar
        self.couldNotLoad = couldNotLoad
        self.pageSize = pageSize
        self.loadedCount = pageSize
    }

    var isEmpty: Bool { products.isEmpty }

    /// How many the shopper is holding, which is not how many are on screen: a carousel shows a
    /// handful, and the heading still says how many there are altogether.
    var savedCount: Int { saved.count }

    func onAppear() {
        guard cancellables.isEmpty else { return }

        savedProductIds()
            .sink { [weak self] ids in
                self?.savedChanged(ids)
            }
            .store(in: &cancellables)
    }

    func onReachEnd() {
        guard loadedCount < saved.count, !isLoading, !isLoadingMore else { return }
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

        let window = Array(saved.prefix(loadedCount))
        let missing = window.filter { cache[$0] == nil }

        guard !missing.isEmpty else {
            isLoading = false
            isLoadingMore = false
            products = window.compactMap { cache[$0] }
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

                /// Asked about, and not described. A shop that answers describes everything it
                /// still sells, so whatever is missing from a successful answer has been stopped.
                /// A *failed* lookup says nothing at all, which is why this is only read here —
                /// a dropped connection must never read as the shop closing down.
                let described = Set(fetched.map(\.id))
                if missing.contains(where: { !described.contains($0) }) {
                    self.somethingHasBeenDiscontinued = true
                }

            case .failure:
                self.snackbar.show(Snackbar(
                    title: self.couldNotLoad,
                    message: "Check your connection and try again.",
                    icon: "wifi.exclamationmark",
                    action: .retry { [weak self] in self?.hydrate(isPaging: isPaging) }
                ))
            }

            self.products = window.compactMap { self.cache[$0] }
            self.isLoading = false
            self.isLoadingMore = false
        }
    }
}
