import Combine
import Foundation
import Money
import Product
import SnackbarUI
@testable import WishlistUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. Tests say what
/// a shopper has kept and what the shop said about it, never which type held it.
///
/// One driver for both lists on the tab, because there is one list *type*: My Faves and Notify Me
/// differ in where their ids come from and in nothing else. A test written here holds for both,
/// which is the payoff for their being one view model rather than two.
final class AKeeper {
    private let kept = CurrentValueSubject<[ProductID], Never>([])
    let shop = StubShop()
    let snackbars = SpySnackbarPresenter()

    private(set) lazy var list = SavedProductsViewModel(
        savedProductIds: { [kept] in kept.eraseToAnyPublisher() },
        lookUpProducts: shop,
        snackbar: snackbars,
        couldNotLoad: "Couldn't Load",
        pageSize: pageSize
    )

    var pageSize = 30

    /// What the shopper is holding — saved, or waiting on. The list only ever sees ids.
    func keeps(_ ids: Int...) {
        kept.send(ids.map(pid))
    }

    func keeps(idsUpTo count: Int) {
        kept.send((1...count).map(pid))
    }

    func stopsKeeping(_ ids: Int...) {
        let dropped = Set(ids.map(pid))
        kept.send(kept.value.filter { !dropped.contains($0) })
    }

    func settle() async {
        for _ in 0..<200 { await Task.yield() }
    }
}

// MARK: - What the app cannot own

/// The shop answers about everything it still sells and says nothing about the rest, which is the
/// only signal it gives that something has been stopped.
final class StubShop: LookUpProductsUseCase, @unchecked Sendable {
    private let lock = NSLock()
    private var _stillSells: Set<ProductID> = []
    private var _cannotBeReached = false
    private var _asked: [[ProductID]] = []

    var stillSells: Set<ProductID> {
        get { lock.withLock { _stillSells } }
        set { lock.withLock { _stillSells = newValue } }
    }

    var cannotBeReached: Bool {
        get { lock.withLock { _cannotBeReached } }
        set { lock.withLock { _cannotBeReached = newValue } }
    }

    var asked: [[ProductID]] { lock.withLock { _asked } }

    func sells(_ ids: Int...) {
        stillSells = Set(ids.map(pid))
    }

    func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
        let answer: Result<[Product], ProductError> = lock.withLock {
            _asked.append(ids)
            guard !_cannotBeReached else { return .failure(.unavailable) }
            return .success(ids.filter { _stillSells.contains($0) }.map { Product.fixture(id: $0.rawValue) })
        }
        return answer
    }
}

@MainActor
final class SpySnackbarPresenter: SnackbarPresenting {
    private(set) var shown: [Snackbar] = []

    func show(_ snackbar: Snackbar) { shown.append(snackbar) }
}

// MARK: - Fixtures

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}

extension Product {
    static func fixture(id: Int) -> Product {
        Product(
            id: pid(id),
            title: "Product \(id)",
            description: "",
            category: CategoryID(rawValue: "beauty"),
            price: Money(amount: 9.99, currency: .usd),
            rating: 4.5,
            availability: .inStock(remaining: 10),
            brand: "Acme",
            thumbnail: "https://cdn.example.com/\(id).png",
            images: []
        )
    }
}
