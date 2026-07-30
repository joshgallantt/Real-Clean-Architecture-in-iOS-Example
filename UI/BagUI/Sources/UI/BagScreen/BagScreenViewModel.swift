import Combine
import Foundation
import Bag
import Product
import SnackbarUI

@MainActor
public final class BagScreenViewModel: ObservableObject {
    @Published private(set) var rows: [BagRow] = []
    @Published private(set) var removedRows: [ChangedBagRow] = []
    @Published private(set) var priceChangedRows: [ChangedBagRow] = []
    @Published private(set) var isLoadingMore = false

    private let pageSize = 30

    private let observeBag: ObserveBagUseCase
    private let observeBagChanges: ObserveBagChangesUseCase
    private let getProductsByIds: GetProductsByIdsUseCase
    private let setBagItemQuantity: SetBagItemQuantityUseCase
    private let bringBagUpToDate: BringBagUpToDateUseCase
    private let acknowledgeBagChange: AcknowledgeBagChangeUseCase
    private let snackbar: SnackbarPresenting

    private var cancellables = Set<AnyCancellable>()
    private var bag = Bag()
    private var changes = BagChanges()
    private var catalog: [Int: Product] = [:]
    private var loadedCount: Int
    private var lookupTask: Task<Void, Never>?

    /// Always from the bag, never from the catalog: the total must be right whether or
    /// not anything loaded.
    var total: Double { bag.total }

    var isEmpty: Bool { bag.isEmpty }

    public init(
        observeBag: ObserveBagUseCase,
        observeBagChanges: ObserveBagChangesUseCase,
        getProductsByIds: GetProductsByIdsUseCase,
        setBagItemQuantity: SetBagItemQuantityUseCase,
        bringBagUpToDate: BringBagUpToDateUseCase,
        acknowledgeBagChange: AcknowledgeBagChangeUseCase,
        snackbar: SnackbarPresenting
    ) {
        self.observeBag = observeBag
        self.observeBagChanges = observeBagChanges
        self.getProductsByIds = getProductsByIds
        self.setBagItemQuantity = setBagItemQuantity
        self.bringBagUpToDate = bringBagUpToDate
        self.acknowledgeBagChange = acknowledgeBagChange
        self.snackbar = snackbar
        self.loadedCount = pageSize
    }

    /// Opening the bag is a reason to ask the shop again — a shopper coming back after a
    /// day is the whole point of catching up, and the tab is held alive between visits,
    /// so nothing else would ever ask.
    ///
    /// It also covers anything added from another tab while this screen was off-screen:
    /// that bag change does not ask on its own, and does not need to, because the shopper
    /// has to come here to see it.
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

    func didChangeQuantity(productId: Int, quantity: Int) {
        setBagItemQuantity(productId: productId, to: quantity)
        askTheShop(aboutEverythingVisible: true)
    }

    // Wanting none of something is the same thing as taking it out, so the bag is told
    // once, in one way.
    func didSwipeToDelete(productId: Int) {
        setBagItemQuantity(productId: productId, to: 0)
        askTheShop(aboutEverythingVisible: true)
    }

    func didAcknowledgeChange(productId: Int) {
        acknowledgeBagChange(productId: productId)
    }

    func didRemoveChangedItem(productId: Int) {
        setBagItemQuantity(productId: productId, to: 0)
        askTheShop(aboutEverythingVisible: true)
    }

    /// Stubbed until there is a push notification system to register with. It dismisses
    /// the row so the shopper is not left with a button that appears to do nothing, and
    /// says what it will eventually mean.
    func didAskToBeNotified(productId: Int) {
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

    /// Redraws, and nothing else. Asking the shop is triggered by the things that
    /// warrant it — opening the screen, and the shopper changing something here — rather
    /// than inferred from the bag having changed. Inferring it means telling the
    /// shopper's own edits apart from the repricing that asking causes, and getting that
    /// wrong makes the screen ask forever.
    private func bagChanged(_ bag: Bag) {
        self.bag = bag

        let ids = Set(bag.items.map(\.id))
        catalog = catalog.filter { ids.contains($0.key) }

        render()
    }

    /// Rows go out immediately from the bag alone. Names and pictures arrive later if
    /// they arrive at all — the shopper's bag is never held hostage to the catalog.
    private func render() {
        rows = bag.items.prefix(loadedCount).map { item in
            BagRow(item: item, name: catalog[item.id]?.title, imageURL: catalog[item.id]?.thumbnail)
        }

        // What is worth saying depends on both, so the domain is asked rather than the
        // screen deciding: a price notice for a line no longer in the bag, or a removal
        // notice for one the shopper has chosen again, is not news.
        let worthSaying = BagReconciliation.worthTelling(changes, about: bag)
        removedRows = worthSaying.noLongerAvailable.map(row(for:))
        priceChangedRows = worthSaying.priceMoves.map(row(for:))
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
                self.bringBagUpToDate(against: products)
            }

            self.isLoadingMore = false
            self.render()
        }
    }
}
