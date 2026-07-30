import Combine
import Foundation
import Bag
import Product
import SnackbarUI

/// A working bag and catalog behind the use case ports the screen is given, wired to
/// each other the way the real ones are: catching up really does save, and saving really
/// does push a new bag back through `observeBag`.
///
/// Lock-protected rather than `@MainActor`, because `GetProductsByIdsUseCase` is not
/// main-actor isolated and the screen calls it from a task that has hopped off.
final class FakeShop: @unchecked Sendable {
    private let lock = NSLock()
    private let bagSubject: CurrentValueSubject<Bag, Never>
    private let changesSubject: CurrentValueSubject<BagChanges, Never>
    private var _lookups: [[Int]] = []
    private var _shownSnackbars: [Snackbar] = []
    private var _catalog: [Product]

    /// Every batch of ids the screen asked the catalog about, in order.
    var lookups: [[Int]] { lock.withLock { _lookups } }
    var shownSnackbars: [Snackbar] { lock.withLock { _shownSnackbars } }
    var currentBag: Bag { bagSubject.value }
    var currentChanges: BagChanges { changesSubject.value }

    /// What the catalog answers with. Change it between visits to move a price or sell
    /// something out.
    var catalog: [Product] {
        get { lock.withLock { _catalog } }
        set { lock.withLock { _catalog = newValue } }
    }

    init(bag: Bag = Bag(), changes: BagChanges = BagChanges(), catalog: [Product] = []) {
        self.bagSubject = CurrentValueSubject(bag)
        self.changesSubject = CurrentValueSubject(changes)
        self._catalog = catalog
    }

    var observeBag: ObserveBagUseCase { Observe(shop: self) }
    var observeBagChanges: ObserveBagChangesUseCase { ObserveChanges(shop: self) }
    var getProductsByIds: GetProductsByIdsUseCase { Lookup(shop: self) }
    var setBagItemQuantity: SetBagItemQuantityUseCase { SetQuantity(shop: self) }
    var reconcile: BringBagUpToDateUseCase { Reconcile(shop: self) }
    var acknowledge: AcknowledgeBagChangeUseCase { Acknowledge(shop: self) }
    @MainActor var snackbar: SnackbarPresenting { Presenter(shop: self) }

    func choose(_ item: BagItem) {
        save(bag: bagSubject.value.adding(item), changes: changesSubject.value.acknowledging(itemId: item.id))
    }

    fileprivate func save(bag: Bag, changes: BagChanges) {
        bagSubject.send(bag)
        changesSubject.send(changes)
    }

    fileprivate func lookUp(_ ids: [Int]) -> [Product] {
        lock.withLock {
            _lookups.append(ids)
            return _catalog.filter { ids.contains($0.id) }
        }
    }

    fileprivate func record(_ snackbar: Snackbar) {
        lock.withLock { _shownSnackbars.append(snackbar) }
    }

    fileprivate var bag: Bag { bagSubject.value }
    fileprivate var changes: BagChanges { changesSubject.value }
    fileprivate func bagPublisher() -> AnyPublisher<Bag, Never> { bagSubject.eraseToAnyPublisher() }
    fileprivate func changesPublisher() -> AnyPublisher<BagChanges, Never> { changesSubject.eraseToAnyPublisher() }

    // MARK: - Ports

    private struct Observe: ObserveBagUseCase {
        let shop: FakeShop
        @MainActor func callAsFunction() -> AnyPublisher<Bag, Never> { shop.bagPublisher() }
    }

    private struct ObserveChanges: ObserveBagChangesUseCase {
        let shop: FakeShop
        @MainActor func callAsFunction() -> AnyPublisher<BagChanges, Never> { shop.changesPublisher() }
    }

    private struct Lookup: GetProductsByIdsUseCase {
        let shop: FakeShop
        func callAsFunction(ids: [Int]) async -> Result<[Product], ProductError> {
            .success(shop.lookUp(ids))
        }
    }

    private struct SetQuantity: SetBagItemQuantityUseCase {
        let shop: FakeShop
        @MainActor func callAsFunction(itemId: Int, to quantity: Int) {
            let bag = shop.bag.changingQuantity(ofItemId: itemId, to: quantity)
            let changes = bag.quantity(forItemId: itemId) == 0
                ? shop.changes.acknowledging(itemId: itemId)
                : shop.changes
            shop.save(bag: bag, changes: changes)
        }
    }

    private struct Reconcile: BringBagUpToDateUseCase {
        let shop: FakeShop
        @MainActor func callAsFunction(prices: [Int: Double], inStock: [Int: Bool]) {
            let caughtUp = BagReconciliation.reconcile(
                bag: shop.bag, changes: shop.changes, prices: prices, inStock: inStock
            )
            guard caughtUp.bag != shop.bag || caughtUp.changes != shop.changes else { return }
            shop.save(bag: caughtUp.bag, changes: caughtUp.changes)
        }
    }

    private struct Acknowledge: AcknowledgeBagChangeUseCase {
        let shop: FakeShop
        @MainActor func callAsFunction(itemId: Int) {
            shop.save(bag: shop.bag, changes: shop.changes.acknowledging(itemId: itemId))
        }
    }

    private final class Presenter: SnackbarPresenting {
        let shop: FakeShop
        init(shop: FakeShop) { self.shop = shop }
        func show(_ snackbar: Snackbar) { shop.record(snackbar) }
    }
}

extension Product {
    static func fixture(
        id: Int,
        price: Double = 9.99,
        stock: Int = 10,
        willRestock: Bool = true
    ) -> Product {
        Product(
            id: id,
            title: "Product \(id)",
            description: "",
            category: CategoryID(rawValue: "beauty"),
            price: price,
            discountPercentage: 0,
            rating: 4.5,
            stock: stock,
            willRestock: willRestock,
            brand: "Acme",
            thumbnail: "https://cdn.example.com/\(id).png",
            images: []
        )
    }
}
