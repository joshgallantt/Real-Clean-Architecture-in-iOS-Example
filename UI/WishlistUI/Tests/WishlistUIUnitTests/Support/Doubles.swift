import Combine
import Foundation
import Money
import Product
import Session
import SnackbarUI
import StockAlert
@testable import WishlistUI

@MainActor
final class StubObserveSession: ObserveSessionUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Session, Never>
    private(set) var callCount = 0

    init(initial: Session = .guest) {
        subject = CurrentValueSubject(initial)
    }

    func callAsFunction() -> AnyPublisher<Session, Never> {
        callCount += 1
        return subject.eraseToAnyPublisher()
    }

    func send(_ session: Session) {
        subject.send(session)
    }
}

@MainActor
final class SpySnackbarPresenter: SnackbarPresenting {
    private(set) var shown: [Snackbar] = []

    func show(_ snackbar: Snackbar) {
        shown.append(snackbar)
    }
}

@MainActor
final class StubGetAlertedProducts {
    var result: Result<[Product], StockAlertError> = .success([])
    private(set) var callCount = 0

    func callAsFunction() async -> Result<[Product], StockAlertError> {
        callCount += 1
        return result
    }
}

@MainActor
final class StubObserveStockAlerts {
    private let subject = CurrentValueSubject<StockAlerts, Never>(StockAlerts())

    func callAsFunction() -> AnyPublisher<StockAlerts, Never> { subject.eraseToAnyPublisher() }

    func send(_ alerts: StockAlerts) { subject.send(alerts) }
}

@MainActor
final class SpyClearTheList {
    private(set) var calls: [[ProductID]] = []

    func callAsFunction(_ ids: [ProductID]) async {
        calls.append(ids)
    }
}

@MainActor
final class StubObserveSavedProductIds {
    private let subject: CurrentValueSubject<[ProductID], Never>

    init(_ ids: [ProductID] = []) {
        subject = CurrentValueSubject(ids)
    }

    func callAsFunction() -> AnyPublisher<[ProductID], Never> { subject.eraseToAnyPublisher() }

    func send(_ ids: [ProductID]) { subject.send(ids) }
}

@MainActor
final class StubLookUpProducts: LookUpProductsUseCase, @unchecked Sendable {
    var result: Result<[Product], ProductError> = .success([])
    private(set) var asked: [[ProductID]] = []

    func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
        asked.append(ids)
        return result
    }
}

@MainActor
func settle() async {
    for _ in 0..<200 { await Task.yield() }
}

// MARK: - Fixtures

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}

extension Product {
    static func fixture(id: Int, availability: Availability = .inStock(remaining: 10)) -> Product {
        Product(
            id: pid(id),
            title: "Product \(id)",
            description: "",
            category: CategoryID(rawValue: "beauty"),
            price: Money(amount: 9.99, currency: .usd),
            rating: 4.5,
            availability: availability,
            brand: "Acme",
            thumbnail: "https://cdn.example.com/\(id).png",
            images: []
        )
    }
}

extension User {
    static func fixture() -> User {
        User(id: UserID(rawValue: 1), email: Email("ada@example.com"), name: PersonName(first: "Ada", last: nil))
    }
}
