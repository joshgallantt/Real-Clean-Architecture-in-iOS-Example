import Combine
import Foundation
import Bag
import Money
import Product
@testable import BagUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: only two things are faked —
/// where the bag is kept and what the catalog answers. The use cases the screen is handed are the
/// real ones, built on this as their repository.
///
/// Fowler, *PoEAA* (2002), Ch. 13 — Repository; Ch. 18 — Gateway.
final class FakeShop: BagRepository {
    private let catalogLock = NSLock()
    private let bagSubject: CurrentValueSubject<Bag, Never>
    private let noticesSubject: CurrentValueSubject<Notices, Never>
    private nonisolated(unsafe) var _lookups: [[ProductID]] = []
    private nonisolated(unsafe) var _catalog: [Product]
    private nonisolated(unsafe) var _cannotBeReached = false

    nonisolated var lookups: [[ProductID]] { catalogLock.withLock { _lookups } }
    var currentBag: Bag { bagSubject.value }
    var currentNotices: Notices { noticesSubject.value }

    nonisolated var catalog: [Product] {
        get { catalogLock.withLock { _catalog } }
        set { catalogLock.withLock { _catalog = newValue } }
    }

    /// Told apart from a shop that answers with nothing, because the two mean opposite things: one
    /// has stopped selling everything, the other has said nothing at all.
    nonisolated var cannotBeReached: Bool {
        get { catalogLock.withLock { _cannotBeReached } }
        set { catalogLock.withLock { _cannotBeReached = newValue } }
    }

    init(bag: Bag = Bag(), notices: Notices = Notices(), catalog: [Product] = []) {
        self.bagSubject = CurrentValueSubject(bag)
        self.noticesSubject = CurrentValueSubject(notices)
        self._catalog = catalog
    }

    // MARK: - The real use cases, over this as their repository

    var observeBag: ObserveBagUseCase { DefaultObserveBagUseCase(repository: self) }
    var observeBagItemQuantity: ObserveBagItemQuantityUseCase {
        DefaultObserveBagItemQuantityUseCase(repository: self)
    }
    var observeNotices: ObserveNoticesUseCase { DefaultObserveNoticesUseCase(repository: self) }
    var setBagItemQuantity: SetBagItemQuantityUseCase { DefaultSetBagItemQuantityUseCase(repository: self) }
    var bringUpToDate: BringBagUpToDateUseCase { DefaultBringBagUpToDateUseCase(repository: self) }
    var acknowledge: AcknowledgeNoticesUseCase { DefaultAcknowledgeNoticesUseCase(repository: self) }
    var addItemToBag: AddItemToBagUseCase { DefaultAddItemToBagUseCase(repository: self) }

    nonisolated var lookUpProducts: LookUpProductsUseCase { Lookup(shop: self) }

    func choose(_ item: BagItem) {
        addItemToBag(item)
    }

    // MARK: - BagRepository

    var bag: Bag { bagSubject.value }
    var bagPublisher: AnyPublisher<Bag, Never> { bagSubject.eraseToAnyPublisher() }
    var notices: Notices { noticesSubject.value }
    var noticesPublisher: AnyPublisher<Notices, Never> { noticesSubject.eraseToAnyPublisher() }

    func save(bag: Bag, notices: Notices) {
        bagSubject.send(bag)
        noticesSubject.send(notices)
    }

    // MARK: -

    nonisolated fileprivate func lookUp(_ ids: [ProductID]) -> [Product] {
        catalogLock.withLock {
            _lookups.append(ids)
            return _catalog.filter { ids.contains($0.id) }
        }
    }

    private struct Lookup: LookUpProductsUseCase {
        let shop: FakeShop
        func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
            guard !shop.cannotBeReached else { return .failure(.unavailable) }
            return .success(shop.lookUp(ids))
        }
    }
}

/// The app layer conforms `Navigator` to this. The bag screen only ever pushes product details, so
/// that is all the test needs to know about.
@MainActor
final class StubNavigation: BagNavigation {
    private(set) var openedProducts: [ProductID] = []

    nonisolated func openProductDetails(id: ProductID) {
        MainActor.assumeIsolated { openedProducts.append(id) }
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
