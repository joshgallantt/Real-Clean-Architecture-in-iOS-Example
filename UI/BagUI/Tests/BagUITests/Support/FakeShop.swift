import Combine
import Foundation
import Bag
import Money
import Product
import SnackbarUI

/// A working bag and catalog behind the use case ports the screen is given.
///
/// Only two things are faked: where the bag is kept, and what the catalog answers. The use
/// cases the screen is handed are the real ones, built on this as their repository — so
/// catching up really reconciles, saving really pushes a new bag back through `observeBag`,
/// and the news the screen receives has really been through the rule about what is still
/// worth telling.
///
/// Lock-protected rather than `@MainActor` throughout, because `LookUpProductsUseCase` is
/// not main-actor isolated and the screen calls it from a task that has hopped off.
@MainActor
final class FakeShop: BagRepository {
    private let catalogLock = NSLock()
    private let bagSubject: CurrentValueSubject<Bag, Never>
    private let changesSubject: CurrentValueSubject<BagChanges, Never>
    private var _lookups: [[ProductID]] = []
    private var _shownSnackbars: [Snackbar] = []
    private var _catalog: [Product]

    /// Every batch of ids the screen asked the catalog about, in order.
    nonisolated var lookups: [[ProductID]] { catalogLock.withLock { _lookups } }
    nonisolated var shownSnackbars: [Snackbar] { catalogLock.withLock { _shownSnackbars } }
    var currentBag: Bag { bagSubject.value }
    var currentChanges: BagChanges { changesSubject.value }

    /// What the catalog answers with. Change it between visits to move a price or sell
    /// something out.
    nonisolated var catalog: [Product] {
        get { catalogLock.withLock { _catalog } }
        set { catalogLock.withLock { _catalog = newValue } }
    }

    init(bag: Bag = Bag(), changes: BagChanges = BagChanges(), catalog: [Product] = []) {
        self.bagSubject = CurrentValueSubject(bag)
        self.changesSubject = CurrentValueSubject(changes)
        self._catalog = catalog
    }

    // MARK: - The real use cases, over this as their repository

    var observeBag: ObserveBagUseCase { DefaultObserveBagUseCase(repository: self) }
    var observeBagChanges: ObserveBagChangesUseCase { DefaultObserveBagChangesUseCase(repository: self) }
    var setBagItemQuantity: SetBagItemQuantityUseCase { DefaultSetBagItemQuantityUseCase(repository: self) }
    var bringUpToDate: BringBagUpToDateUseCase { DefaultBringBagUpToDateUseCase(repository: self) }
    var acknowledge: AcknowledgeBagChangeUseCase { DefaultAcknowledgeBagChangeUseCase(repository: self) }
    var addItemToBag: AddItemToBagUseCase { DefaultAddItemToBagUseCase(repository: self) }

    /// The catalog is the one thing genuinely stubbed here.
    nonisolated var lookUpProducts: LookUpProductsUseCase { Lookup(shop: self) }

    var snackbar: SnackbarPresenting { Presenter(shop: self) }

    func choose(_ item: BagItem) {
        addItemToBag(item)
    }

    // MARK: - BagRepository

    var bag: Bag { bagSubject.value }
    var bagPublisher: AnyPublisher<Bag, Never> { bagSubject.eraseToAnyPublisher() }
    var changes: BagChanges { changesSubject.value }
    var changesPublisher: AnyPublisher<BagChanges, Never> { changesSubject.eraseToAnyPublisher() }

    func save(bag: Bag, changes: BagChanges) {
        bagSubject.send(bag)
        changesSubject.send(changes)
    }

    // MARK: -

    nonisolated fileprivate func lookUp(_ ids: [ProductID]) -> [Product] {
        catalogLock.withLock {
            _lookups.append(ids)
            return _catalog.filter { ids.contains($0.id) }
        }
    }

    nonisolated fileprivate func record(_ snackbar: Snackbar) {
        catalogLock.withLock { _shownSnackbars.append(snackbar) }
    }

    private struct Lookup: LookUpProductsUseCase {
        let shop: FakeShop
        func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
            .success(shop.lookUp(ids))
        }
    }

    private final class Presenter: SnackbarPresenting {
        let shop: FakeShop
        init(shop: FakeShop) { self.shop = shop }
        func show(_ snackbar: Snackbar) { shop.record(snackbar) }
    }
}

// MARK: - Fixtures

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}

func usd(_ amount: Decimal) -> Money {
    Money(amount: amount, currency: .usd)
}

func bagItem(_ id: Int, quantity: Int = 1, price: Decimal, addedAt: Date = Date()) -> BagItem {
    BagItem(productId: pid(id), quantity: quantity, lastKnownPrice: usd(price), dateAdded: addedAt)
}

extension Product {
    static func fixture(
        id: Int,
        price: Decimal = 9.99,
        availability: Availability = .inStock(remaining: 10)
    ) -> Product {
        Product(
            id: pid(id),
            title: "Product \(id)",
            description: "",
            category: CategoryID(rawValue: "beauty"),
            price: usd(price),
            rating: 4.5,
            availability: availability,
            brand: "Acme",
            thumbnail: "https://cdn.example.com/\(id).png",
            images: []
        )
    }
}
