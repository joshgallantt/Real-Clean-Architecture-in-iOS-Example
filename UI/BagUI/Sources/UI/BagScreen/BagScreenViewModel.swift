import Combine
import Foundation
import Bag
import Product

@MainActor
public final class BagScreenViewModel: ObservableObject {
    @Published private(set) var rows: [BagRow] = []
    @Published private(set) var changedRows: [ChangedBagRow] = []
    @Published private(set) var isLoadingMore = false

    private let pageSize = 30

    private let observeBag: ObserveBagUseCase
    private let getProductsByIds: GetProductsByIdsUseCase
    private let setBagItemQuantity: SetBagItemQuantityUseCase
    private let reconcileBag: ReconcileBagUseCase
    private let acknowledgeBagChange: AcknowledgeBagChangeUseCase

    private var cancellables = Set<AnyCancellable>()
    private var bag = Bag()
    private var catalog: [Int: Product] = [:]
    private var loadedCount: Int
    private var lookupTask: Task<Void, Never>?

    /// What the shopper has chosen, ignoring what it costs. Used to tell their own edits
    /// apart from the repricing that catching up causes — otherwise saving a reconciled
    /// bag would look like a change and ask the shop again, forever.
    private var chosenContents: [Int: Int] = [:]

    /// Always from the bag, never from the catalog: the total must be right whether or
    /// not anything loaded.
    var total: Double { bag.total }

    var isEmpty: Bool { bag.isEmpty }

    public init(
        observeBag: ObserveBagUseCase,
        getProductsByIds: GetProductsByIdsUseCase,
        setBagItemQuantity: SetBagItemQuantityUseCase,
        reconcileBag: ReconcileBagUseCase,
        acknowledgeBagChange: AcknowledgeBagChangeUseCase
    ) {
        self.observeBag = observeBag
        self.getProductsByIds = getProductsByIds
        self.setBagItemQuantity = setBagItemQuantity
        self.reconcileBag = reconcileBag
        self.acknowledgeBagChange = acknowledgeBagChange
        self.loadedCount = pageSize
    }

    /// Opening the bag is a reason to ask the shop again — a shopper coming back after
    /// a day is the whole point of catching up, and the tab is held alive between
    /// visits, so nothing else would ever ask.
    func onAppear() {
        guard !cancellables.isEmpty else {
            subscribe()
            return
        }
        askTheShop(aboutEverythingVisible: true)
    }

    func onReachEnd() {
        guard loadedCount < bag.items.count, !isLoadingMore else { return }
        loadedCount += pageSize
        render()
        askTheShop(aboutEverythingVisible: false)
    }

    func didChangeQuantity(itemId: Int, quantity: Int) {
        setBagItemQuantity(itemId: itemId, to: quantity)
    }

    // Wanting none of something is the same thing as taking it out, so the bag is told
    // once, in one way.
    func didSwipeToDelete(itemId: Int) {
        setBagItemQuantity(itemId: itemId, to: 0)
    }

    func didAcknowledgeChange(itemId: Int) {
        acknowledgeBagChange(itemId: itemId)
    }

    func didRemoveChangedItem(itemId: Int) {
        setBagItemQuantity(itemId: itemId, to: 0)
    }

    // MARK: -

    private func subscribe() {
        observeBag()
            .sink { [weak self] bag in
                self?.bagChanged(bag)
            }
            .store(in: &cancellables)
    }

    private func bagChanged(_ bag: Bag) {
        let previousContents = chosenContents
        self.bag = bag
        chosenContents = Dictionary(uniqueKeysWithValues: bag.items.map { ($0.id, $0.quantity) })

        let ids = Set(bag.items.map(\.id))
        catalog = catalog.filter { ids.contains($0.key) }

        render()

        // Adding, removing or changing how many is also a reason to ask. Repricing is
        // not: that came from the shop's own answer, and asking again would loop.
        if chosenContents != previousContents {
            askTheShop(aboutEverythingVisible: true)
        }
    }

    /// Rows go out immediately from the bag alone. Names and pictures arrive later if
    /// they arrive at all — the shopper's bag is never held hostage to the catalog.
    private func render() {
        rows = bag.items.prefix(loadedCount).map { item in
            BagRow(item: item, name: catalog[item.id]?.title, imageURL: catalog[item.id]?.thumbnail)
        }

        changedRows = bag.pendingChanges.map { change in
            ChangedBagRow(
                change: change,
                name: catalog[change.itemId]?.title,
                imageURL: catalog[change.itemId]?.thumbnail
            )
        }
    }

    /// - Parameter aboutEverythingVisible: ask again about lines already looked up, so
    ///   prices and stock can be checked. `false` asks only about lines never seen, which
    ///   is all paging needs.
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
            let result = await self.getProductsByIds(ids: ids)
            guard !Task.isCancelled else { return }

            // A failure leaves the rows as they were and says nothing. There is no retry
            // to offer, because nothing the shopper asked for has failed.
            if case .success(let products) = result {
                for product in products {
                    self.catalog[product.id] = product
                }
                self.catchUp(with: products)
            }

            self.isLoadingMore = false
            self.render()
        }
    }

    /// The catalog's answer becomes the two facts the bag understands. Stock is a count
    /// to the shop and a yes-or-no to a bag, and the translation happens here rather
    /// than letting the bag learn what a `Product` is.
    private func catchUp(with products: [Product]) {
        reconcileBag(
            prices: Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0.price) }),
            inStock: Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0.stock > 0) })
        )
    }
}
