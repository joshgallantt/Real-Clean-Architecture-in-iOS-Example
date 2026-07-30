import Combine
import Foundation
import Bag
import Money
import Product

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class BagScreenViewModel: ObservableObject {
    @Published private(set) var rows: [BagRow] = []
    @Published private(set) var outOfStockRows: [ChangedBagRow] = []
    @Published private(set) var discontinuedRows: [ChangedBagRow] = []
    @Published private(set) var priceIncreaseRows: [ChangedBagRow] = []
    @Published private(set) var priceDecreaseRows: [ChangedBagRow] = []
    @Published private(set) var shortageRows: [ChangedBagRow] = []

    private let observeBag: ObserveBagUseCase
    private let observeBagChanges: ObserveBagChangesUseCase
    private let lookUpProducts: LookUpProductsUseCase
    private let setBagItemQuantity: SetBagItemQuantityUseCase
    private let bringBagUpToDate: BringBagUpToDateUseCase
    private let acknowledgeBagChange: AcknowledgeBagChangeUseCase

    private var cancellables = Set<AnyCancellable>()
    private var bag = Bag()
    private var changes = BagChanges()
    private var catalog: [ProductID: Product] = [:]
    private var lookupTask: Task<Void, Never>?

    /// Fowler, *PoEAA* (2002) — Money: always from the bag, never the catalog, so the total is
    /// right whether or not anything loaded.
    var total: Money? { bag.total }

    var isEmpty: Bool { bag.isEmpty }

    /// Whether there is anything to tell the shopper. An empty bag with notices still waiting is
    /// not an empty screen — the notices are the reason it emptied.
    var hasNews: Bool {
        !outOfStockRows.isEmpty
            || !discontinuedRows.isEmpty
            || !shortageRows.isEmpty
            || !priceIncreaseRows.isEmpty
            || !priceDecreaseRows.isEmpty
    }

    var itemCountSummary: String {
        bag.itemCount == 1 ? "1 item" : "\(bag.itemCount) items"
    }

    public init(
        observeBag: ObserveBagUseCase,
        observeBagChanges: ObserveBagChangesUseCase,
        lookUpProducts: LookUpProductsUseCase,
        setBagItemQuantity: SetBagItemQuantityUseCase,
        bringBagUpToDate: BringBagUpToDateUseCase,
        acknowledgeBagChange: AcknowledgeBagChangeUseCase
    ) {
        self.observeBag = observeBag
        self.observeBagChanges = observeBagChanges
        self.lookUpProducts = lookUpProducts
        self.setBagItemQuantity = setBagItemQuantity
        self.bringBagUpToDate = bringBagUpToDate
        self.acknowledgeBagChange = acknowledgeBagChange
    }

    func onAppear() {
        if cancellables.isEmpty {
            subscribe()
        }
        askTheShop()
    }

    func didChangeQuantity(productId: ProductID, quantity: Int) {
        setBagItemQuantity(productId: productId, to: quantity)
        askTheShop()
    }

    func didSwipeToDelete(productId: ProductID) {
        setBagItemQuantity(productId: productId, to: 0)
        askTheShop()
    }

    func didAcknowledgeChange(productId: ProductID) {
        acknowledgeBagChange(productId: productId)
    }

    /// Acknowledging is by product, not by notice — "Okay" has always meant "I have seen what
    /// happened to this one". So accepting a whole section clears anything else outstanding about
    /// the same product, which is the same thing tapping each Okay in turn would have done.
    func didAcceptAll(_ rows: [ChangedBagRow]) {
        for row in rows {
            acknowledgeBagChange(productId: row.id)
        }
    }

    /// The shopper empties their own bag. Every line goes the way a single swipe sends one, so
    /// there is no second path through the domain to keep in step with the first.
    func didRemoveEverything() {
        for item in bag.items {
            setBagItemQuantity(productId: item.id, to: 0)
        }
        askTheShop()
    }

    func didRemoveChangedItem(productId: ProductID) {
        setBagItemQuantity(productId: productId, to: 0)
        askTheShop()
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
        render()
    }

    /// Every product on screen: what is in the bag, and what the notices are about. The two are not
    /// the same set — a notice that something has gone outlives the line it refers to, which is the
    /// whole point of it — so a screen that keeps only what the bag holds cannot say what it was.
    ///
    /// The bag and the notices reach this screen on two publishers and land one after the other, so
    /// there is a moment where a product has left the bag and its notice has not yet arrived.
    /// Nothing is discarded on that edge; the set is only ever narrowed where both are settled.
    private var productsOnScreen: Set<ProductID> {
        Set(bag.items.map(\.id)).union(changes.all.map(\.productId))
    }

    private func render() {
        rows = bag.items.map { item in
            BagRow(item: item, name: catalog[item.id]?.title, imageURL: catalog[item.id]?.thumbnail)
        }

        outOfStockRows = changes.outOfStock.map(row(for:))
        discontinuedRows = changes.discontinued.map(row(for:))
        priceIncreaseRows = changes.priceIncreases.map(row(for:))
        priceDecreaseRows = changes.priceDecreases.map(row(for:))
        shortageRows = changes.shortages.map(row(for:))
    }

    /// The whole bag, every time, not a page of it.
    ///
    /// Asking page by page meant the bag caught up page by page: prices settled and sold-out lines
    /// left only once a shopper had scrolled far enough to ask about them, so the total moved under
    /// them as they scrolled. A total that changes while you read it is not a total. What a bag is
    /// worth is a fact about all of it, so all of it is what gets asked about.
    private func askTheShop() {
        lookupTask?.cancel()

        let onScreen = productsOnScreen
        catalog = catalog.filter { onScreen.contains($0.key) }

        guard !onScreen.isEmpty else { return }

        lookupTask = Task { [weak self] in
            guard let self else { return }
            let result = await self.lookUpProducts(ids: Array(onScreen))
            guard !Task.isCancelled else { return }

            if case .success(let products) = result {
                for product in products {
                    self.catalog[product.id] = product
                }
                self.bringBagUpToDate(against: products.map(self.whatTheShopSays))
            }

            self.render()
        }
    }

    /// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the Interface Adapters
    /// ring converting the catalog's format into the one the bag's use case wants. The screen
    /// fetches products for names and thumbnails anyway; this is the same answer, narrowed.
    private func whatTheShopSays(about product: Product) -> ShopSays {
        ShopSays(
            productId: product.id,
            price: product.price,
            availability: product.availability
        )
    }
}
