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

    /// Only the sections with something in them, in the order they are read. Five published arrays
    /// and an if-statement each is what this replaced; the view now draws whatever it is given.
    @Published private(set) var noticeSections: [NoticeSection] = []

    private let navigation: BagNavigation
    private let observeBag: ObserveBagUseCase
    private let observeNotices: ObserveNoticesUseCase
    private let lookUpProducts: LookUpProductsUseCase
    private let setBagItemQuantity: SetBagItemQuantityUseCase
    private let bringBagUpToDate: BringBagUpToDateUseCase
    private let acknowledgeNotices: AcknowledgeNoticesUseCase

    private var cancellables = Set<AnyCancellable>()
    private var bag = Bag()
    private var news = Notices()
    private var catalog: [ProductID: Product] = [:]
    private var lookupTask: Task<Void, Never>?

    /// Fowler, *PoEAA* (2002), Ch. 18 — Money: always from the bag, never the catalog, so the total
    /// is right whether or not anything loaded.
    var total: Money? { bag.total }

    var isEmpty: Bool { bag.isEmpty }

    /// Whether there is anything to tell the shopper. An empty bag with notices still waiting is
    /// not an empty screen — the notices are the reason it emptied.
    var hasNews: Bool { !noticeSections.isEmpty }

    func notices(in kind: Notice.Kind) -> [NoticeRow] {
        noticeSections.first { $0.kind == kind }?.rows ?? []
    }

    var itemCountSummary: String {
        bag.itemCount == 1 ? "1 item" : "\(bag.itemCount) items"
    }

    public init(
        navigation: BagNavigation,
        observeBag: ObserveBagUseCase,
        observeNotices: ObserveNoticesUseCase,
        lookUpProducts: LookUpProductsUseCase,
        setBagItemQuantity: SetBagItemQuantityUseCase,
        bringBagUpToDate: BringBagUpToDateUseCase,
        acknowledgeNotices: AcknowledgeNoticesUseCase
    ) {
        self.navigation = navigation
        self.observeBag = observeBag
        self.observeNotices = observeNotices
        self.lookUpProducts = lookUpProducts
        self.setBagItemQuantity = setBagItemQuantity
        self.bringBagUpToDate = bringBagUpToDate
        self.acknowledgeNotices = acknowledgeNotices
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

    /// A line in the bag goes to its product. Opening it is behaviour, so it lives here rather than
    /// being called straight out of the view — where nothing could reach it, which is why the bag
    /// screen has had a `StubNavigation` that no test ever asserted on.
    func didTapRow(productId: ProductID) {
        navigation.openProductDetails(id: productId)
    }

    /// A line in a notice goes to its product too, where the section has a product left to go to.
    /// Whether it has is the section's to say — the view asks rather than keeping its own list of
    /// which of the five are worth a trip.
    func didTapNotice(in kind: Notice.Kind, productId: ProductID) {
        guard noticeSections.first(where: { $0.kind == kind })?.opensTheProduct == true else { return }
        navigation.openProductDetails(id: productId)
    }

    /// Acknowledging is by product, not by notice — "Okay" has always meant "I have seen what
    /// happened to this one". So accepting a whole section clears anything else outstanding about
    /// the same product, which is the same thing tapping each Okay in turn would have done.
    ///
    /// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: the shopper accepts a
    /// section, so a section is what this is told. It used to be handed the rows themselves, read
    /// back off the property they came from — which let a caller pair one section's button with
    /// another section's contents, and said nothing a reader would recognise.
    func didAcceptAll(_ kind: Notice.Kind) {
        for row in notices(in: kind) {
            acknowledgeNotices(aboutProductId: row.id)
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

    // MARK: -

    private func subscribe() {
        observeBag()
            .sink { [weak self] bag in
                self?.bag = bag
                self?.render()
            }
            .store(in: &cancellables)

        observeNotices()
            .sink { [weak self] news in
                self?.news = news
                self?.render()
            }
            .store(in: &cancellables)
    }

    /// Every product on screen: what is in the bag, and what the notices are about. The two are not
    /// the same set — a notice that something has gone outlives the line it refers to, which is the
    /// whole point of it — so a screen that keeps only what the bag holds cannot say what it was.
    ///
    /// The bag and the notices reach this screen on two publishers and land one after the other, so
    /// there is a moment where a product has left the bag and its notice has not yet arrived.
    /// Nothing is discarded on that edge; the set is only ever narrowed where both are settled.
    private var productsOnScreen: Set<ProductID> {
        Set(bag.items.map(\.id)).union(news.all.map(\.productId))
    }

    private func render() {
        rows = bag.items.map { item in
            BagRow(item: item, name: catalog[item.id]?.title, imageURL: catalog[item.id]?.thumbnail)
        }

        noticeSections = NoticeSection.readingOrder
            .map { kind in NoticeSection(kind, rows: noticeRows(for: news.of(kind))) }
            .filter { !$0.rows.isEmpty }
    }

    private func noticeRows(for notices: [Notice]) -> [NoticeRow] {
        notices.map { notice in
            NoticeRow(
                notice: notice,
                name: catalog[notice.productId]?.title,
                imageURL: catalog[notice.productId]?.thumbnail
            )
        }
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
