import Combine
import Foundation
import Product
import Session
import SnackbarUI
import Wishlist

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class WishlistScreenViewModel: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isAuthenticated = false

    /// Whether anything saved has been stopped. Not *which* things: the shop learns us of it by
    /// no longer answering about them, so there is no name and no picture to show — one sentence
    /// says everything that is known.
    @Published private(set) var somethingHasBeenDiscontinued = false

    private let pageSize = 30

    private let observeWishlist: ObserveWishlistUseCase
    private let lookUpProducts: LookUpProductsUseCase
    private let observeSession: ObserveSessionUseCase
    private let snackbar: SnackbarPresenting
    private var cancellables = Set<AnyCancellable>()
    private var wishlist = Wishlist()
    private var cache: [ProductID: Product] = [:]
    private var loadedCount: Int
    private var hydrationTask: Task<Void, Never>?

    public init(
        observeWishlist: ObserveWishlistUseCase,
        lookUpProducts: LookUpProductsUseCase,
        observeSession: ObserveSessionUseCase,
        snackbar: SnackbarPresenting
    ) {
        self.observeWishlist = observeWishlist
        self.lookUpProducts = lookUpProducts
        self.observeSession = observeSession
        self.snackbar = snackbar
        self.loadedCount = pageSize
    }

    func onAppear() {
        guard cancellables.isEmpty else { return }

        observeSession()
            .sink { [weak self] session in
                self?.isAuthenticated = session.isLoggedIn
            }
            .store(in: &cancellables)

        observeWishlist()
            .sink { [weak self] wishlist in
                self?.wishlistChanged(wishlist)
            }
            .store(in: &cancellables)
    }

    func onReachEnd() {
        guard loadedCount < wishlist.itemCount, !isLoading, !isLoadingMore else { return }
        loadedCount += pageSize
        hydrate(isPaging: true)
    }

    private func wishlistChanged(_ wishlist: Wishlist) {
        self.wishlist = wishlist

        let ids = Set(wishlist.items.map(\.id))
        cache = cache.filter { ids.contains($0.key) }

        hydrate(isPaging: false)
    }

    private func hydrate(isPaging: Bool) {
        hydrationTask?.cancel()

        let window = Array(wishlist.items.prefix(loadedCount))
        let missing = window.map(\.id).filter { cache[$0] == nil }

        guard !missing.isEmpty else {
            isLoading = false
            isLoadingMore = false
            products = window.compactMap { cache[$0.id] }
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
                /// A *failed* lookup says nothing at all, which is why this is only read here.
                let described = Set(fetched.map(\.id))
                if missing.contains(where: { !described.contains($0) }) {
                    self.somethingHasBeenDiscontinued = true
                }
            case .failure:
                self.snackbar.show(Snackbar(
                    title: "Couldn't Load Wishlist",
                    message: "Check your connection and try again.",
                    icon: "wifi.exclamationmark",
                    action: .retry { [weak self] in self?.hydrate(isPaging: isPaging) }
                ))
            }

            self.products = window.compactMap { self.cache[$0.id] }
            self.isLoading = false
            self.isLoadingMore = false
        }
    }
}
