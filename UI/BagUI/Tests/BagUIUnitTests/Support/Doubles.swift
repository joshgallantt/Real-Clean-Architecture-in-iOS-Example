import Combine
import Foundation
import Bag
import Money
import Product
@testable import BagUI

@MainActor
final class StubObserveBag: ObserveBagUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Bag, Never>

    init(_ bag: Bag = Bag()) {
        subject = CurrentValueSubject(bag)
    }

    func callAsFunction() -> AnyPublisher<Bag, Never> { subject.eraseToAnyPublisher() }

    func send(_ bag: Bag) { subject.send(bag) }
}

@MainActor
final class StubObserveNotices: ObserveNoticesUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Notices, Never>

    init(_ notices: Notices = Notices()) {
        subject = CurrentValueSubject(notices)
    }

    func callAsFunction() -> AnyPublisher<Notices, Never> { subject.eraseToAnyPublisher() }

    func send(_ notices: Notices) { subject.send(notices) }
}

@MainActor
final class SpySetBagItemQuantity: SetBagItemQuantityUseCase, @unchecked Sendable {
    private(set) var calls: [(productId: ProductID, quantity: Int)] = []

    func callAsFunction(productId: ProductID, to quantity: Int) {
        calls.append((productId, quantity))
    }
}

@MainActor
final class StubBringBagUpToDate: BringBagUpToDateUseCase, @unchecked Sendable {
    var products: [Product] = []
    private(set) var callCount = 0

    func callAsFunction() async -> [Product] {
        callCount += 1
        return products
    }
}

@MainActor
final class SpyAcknowledgeNotices: AcknowledgeNoticesUseCase, @unchecked Sendable {
    private(set) var acknowledged: [ProductID] = []

    func callAsFunction(aboutProductId productId: ProductID) {
        acknowledged.append(productId)
    }
}

@MainActor
final class SpyNavigation: BagNavigation {
    private(set) var openedProducts: [ProductID] = []

    nonisolated func openProductDetails(id: ProductID) {
        MainActor.assumeIsolated { openedProducts.append(id) }
    }
}

@MainActor
func yieldUntil(_ isSatisfied: () -> Bool) async {
    for _ in 0..<1_000 where !isSatisfied() { await Task.yield() }
}

@MainActor
func settle() async {
    for _ in 0..<200 { await Task.yield() }
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
