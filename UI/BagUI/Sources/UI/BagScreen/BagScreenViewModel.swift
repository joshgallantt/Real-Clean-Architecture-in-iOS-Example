import Combine
import Foundation
import Bag
import Money
import Product
import SnackbarUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class BagScreenViewModel: ObservableObject {
    @Published private(set) var rows: [BagRow] = []
    @Published private(set) var removedRows: [ChangedBagRow] = []
    @Published private(set) var priceChangedRows: [ChangedBagRow] = []
    @Published private(set) var shortageRows: [ChangedBagRow] = []
    @Published private(set) var isLoadingMore = false

    private let pageSize = 30

    private let observeBag: ObserveBagUseCase
    private let observeBagChanges: ObserveBagChangesUseCase
    private let lookUpProducts: LookUpProductsUseCase
    private let setBagItemQuantity: SetBagItemQuantityUseCase
    private let bringBagUpToDate: BringBagUpToDateUseCase
    private let acknowledgeBagChange: AcknowledgeBagChangeUseCase
    private let snackbar: SnackbarPresenting

    private var cancellables = Set<AnyCancellable>()
    private var bag = Bag()
    private var changes = BagChanges()
    private var catalog: [ProductID: Product] = [:]
    private var loadedCount: Int
    private var lookupTask: Task<Void, Never>?

    /// Fowler, *PoEAA* (2002) — Money: always from the bag, never the catalog, so the total is
    /// right whether or not anything loaded.
    var total: Money? { bag.total }

    var isEmpty: Bool { bag.isEmpty }

    public init(
        observeBag: ObserveBagUseCase,
        observeBagChanges: ObserveBagChangesUseCase,
        lookUpProducts: LookUpProductsUseCase,
        setBagItemQuantity: SetBagItemQuantityUseCase,
        bringBagUpToDate: BringBagUpToDateUseCase,
        acknowledgeBagChange: AcknowledgeBagChangeUseCase,
        snackbar: SnackbarPresenting
    ) {
        self.observeBag = observeBag
        self.observeBagChanges = observeBagChanges
        self.lookUpProducts = lookUpProducts
        self.setBagItemQuantity = setBagItemQuantity
        self.bringBagUpToDate = bringBagUpToDate
        self.acknowledgeBagChange = acknowledgeBagChange
        self.snackbar = snackbar
        self.loadedCount = pageSize
    }

    func onAppear() {
        if cancellables.isEmpty {
            subscribe()
        }
        askTheShop(aboutEverythingVisible: true)
    }

    func onReachEnd() {
        guard loadedCount < bag.items.count, !isLoadingMore else { return }
        loadedCount += pageSize
        render()
        askTheShop(aboutEverythingVisible: false)
    }

    func didChangeQuantity(productId: ProductID, quantity: Int) {
        setBagItemQuantity(productId: productId, to: quantity)
        askTheShop(aboutEverythingVisible: true)
    }

    func didSwipeToDelete(productId: ProductID) {
        setBagItemQuantity(productId: productId, to: 0)
        askTheShop(aboutEverythingVisible: true)
    }

    func didAcknowledgeChange(productId: ProductID) {
        acknowledgeBagChange(productId: productId)
    }

    func didRemoveChangedItem(productId: ProductID) {
        setBagItemQuantity(productId: productId, to: 0)
        askTheShop(aboutEverythingVisible: true)
    }

    func didAskToBeNotified(productId: ProductID) {
        acknowledgeBagChange(productId: productId)
        snackbar.show(Snackbar(
            title: "We'll Let You Know",
            message: "You'll hear from us when this is back in stock.",
            icon: "bell.fill"
        ))
    }

    private func row(for change: BagChange) -> ChangedBagRow {
        ChangedBagRow(
            change: change,
            name: catalog[change.productId]?.title,
            imageURL: catalog[change.productId]?.thumbnail
        )
    }

    // MARK: -

    private func subscribe() {
        observeBag()
            .sink { [weak self] bag in
                self?.bagChanged(bag)
            }
            .store(in: &cancellables)

        observeBagChanges()
            .sink { [weak self] changes in
                self?.changes = changes
                self?.render()
            }
            .store(in: &cancellables)
    }

    private func bagChanged(_ bag: Bag) {
        self.bag = bag

        let ids = Set(bag.items.map(\.id))
        catalog = catalog.filter { ids.contains($0.key) }

        render()
    }

    private func render() {
        rows = bag.items.prefix(loadedCount).map { item in
            BagRow(item: item, name: catalog[item.id]?.title, imageURL: catalog[item.id]?.thumbnail)
        }

        removedRows = changes.noLongerAvailable.map(row(for:))
        priceChangedRows = changes.priceMoves.map(row(for:))
        shortageRows = changes.shortages.map(row(for:))
    }

    private func askTheShop(aboutEverythingVisible refreshAll: Bool) {
        lookupTask?.cancel()

        let window = Array(bag.items.prefix(loadedCount))
        let ids = refreshAll ? window.map(\.id) : window.map(\.id).filter { catalog[$0] == nil }
        guard !ids.isEmpty else {
            isLoadingMore = false
            return
        }

        isLoadingMore = rows.contains { $0.name == nil } && window.count > pageSize
        lookupTask = Task { [weak self] in
            guard let self else { return }
            let result = await self.lookUpProducts(ids: ids)
            guard !Task.isCancelled else { return }

            if case .success(let products) = result {
                for product in products {
                    self.catalog[product.id] = product
                }
                self.bringBagUpToDate(against: products.map(ShopSays.init))
            }

            self.isLoadingMore = false
            self.render()
        }
    }
}

/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the Interface Adapters
/// ring converting the catalog's format into the one the bag's use case wants. The screen fetches
/// products for names and thumbnails anyway; this is the same answer, narrowed.
private extension ShopSays {
    init(_ product: Product) {
        self.init(
            productId: product.id,
            price: product.price,
            availability: product.availability
        )
    }
}
