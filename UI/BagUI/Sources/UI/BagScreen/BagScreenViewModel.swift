import Combine
import Foundation
import Product
import SnackbarUI
import Bag

@MainActor
public final class BagScreenViewModel: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var quantities: [Int: Int] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false

    private let pageSize = 30

    private let observeBag: ObserveBagUseCase
    private let getProductsByIds: GetProductsByIdsUseCase
    private let updateBagItemQuantity: UpdateBagItemQuantityUseCase
    private let removeProductFromBag: RemoveProductFromBagUseCase
    private let snackbar: SnackbarPresenting
    private var cancellables = Set<AnyCancellable>()
    private var items: [BagItem] = []
    private var cache: [Int: Product] = [:]
    private var loadedCount: Int
    private var hydrationTask: Task<Void, Never>?

    public var total: Double {
        products.reduce(0) { $0 + $1.price * Double(quantities[$1.id] ?? 0) }
    }

    public init(
        observeBag: ObserveBagUseCase,
        getProductsByIds: GetProductsByIdsUseCase,
        updateBagItemQuantity: UpdateBagItemQuantityUseCase,
        removeProductFromBag: RemoveProductFromBagUseCase,
        snackbar: SnackbarPresenting
    ) {
        self.observeBag = observeBag
        self.getProductsByIds = getProductsByIds
        self.updateBagItemQuantity = updateBagItemQuantity
        self.removeProductFromBag = removeProductFromBag
        self.snackbar = snackbar
        self.loadedCount = pageSize
    }

    func onAppear() {
        guard cancellables.isEmpty else { return }

        // Ids and quantities are cheap to carry in full; only the visible window
        // is ever hydrated into products, so the bag can hold thousands of entries.
        observeBag()
            .sink { [weak self] items in
                self?.bagChanged(items)
            }
            .store(in: &cancellables)
    }

    func onReachEnd() {
        guard loadedCount < items.count, !isLoading, !isLoadingMore else { return }
        loadedCount += pageSize
        hydrate(isPaging: true)
    }

    func didChangeQuantity(productId: Int, quantity: Int) {
        Task { [weak self] in
            guard let self else { return }
            switch await self.updateBagItemQuantity(productId: productId, quantity: quantity) {
            case .success:
                break
            case .failure(.network):
                self.snackbar.show(Snackbar(
                    title: "Couldn't Update Bag",
                    message: "Check your connection and try again.",
                    icon: "wifi.slash",
                    action: .retry { [weak self] in
                        Task { await self?.didChangeQuantity(productId: productId, quantity: quantity) }
                    }
                ))
            }
        }
    }

    func didSwipeToDelete(productId: Int) {
        Task { [weak self] in
            guard let self else { return }
            switch await self.removeProductFromBag(productId: productId) {
            case .success:
                break
            case .failure(.network):
                self.snackbar.show(Snackbar(
                    title: "Couldn't Remove Item",
                    message: "Check your connection and try again.",
                    icon: "wifi.slash",
                    action: .retry { [weak self] in Task { await self?.didSwipeToDelete(productId: productId) } }
                ))
            }
        }
    }

    private func bagChanged(_ items: [BagItem]) {
        self.items = items
        self.quantities = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0.quantity) })

        let ids = Set(items.map(\.id))
        cache = cache.filter { ids.contains($0.key) }

        hydrate(isPaging: false)
    }

    private func hydrate(isPaging: Bool) {
        // A newer window supersedes any in-flight one, so a slow fetch can never
        // clobber newer state.
        hydrationTask?.cancel()

        let window = Array(items.prefix(loadedCount))
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
            let result = await self.getProductsByIds(ids: missing)
            guard !Task.isCancelled else { return }

            switch result {
            case .success(let fetched):
                for product in fetched {
                    self.cache[product.id] = product
                }
            case .failure:
                self.snackbar.show(Snackbar(
                    title: "Couldn't Load Bag",
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
