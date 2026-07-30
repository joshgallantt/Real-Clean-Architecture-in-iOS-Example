import Combine
import Foundation
import Bag
import Money
import Product
import Session
import StockAlert
import AuthUI
import SnackbarUI
@testable import ProductActionsUI

@MainActor
final class InMemoryBagRepository: BagRepository {
    private let bagSubject = CurrentValueSubject<Bag, Never>(Bag())
    private let changesSubject = CurrentValueSubject<BagChanges, Never>(BagChanges())

    var bag: Bag { bagSubject.value }
    var bagPublisher: AnyPublisher<Bag, Never> { bagSubject.eraseToAnyPublisher() }
    var changes: BagChanges { changesSubject.value }
    var changesPublisher: AnyPublisher<BagChanges, Never> { changesSubject.eraseToAnyPublisher() }

    func save(bag: Bag, changes: BagChanges) {
        bagSubject.value = bag
        changesSubject.value = changes
    }
}

@MainActor
/// A working repository rather than a stub with canned answers, so the real use cases genuinely
/// read, apply and save. `whenItCannotKeep` is the one thing a disk does that memory does not.
final class InMemoryStockAlertRepository: StockAlertRepository {
    private let subject = CurrentValueSubject<StockAlerts, Never>(StockAlerts())

    var isSignedIn = true
    var signsInOnPrompt = false
    var whenItCannotKeep = false

    var alerts: StockAlerts { subject.value }
    var alertsPublisher: AnyPublisher<StockAlerts, Never> { subject.eraseToAnyPublisher() }

    var session: GetSessionUseCase { Session_(repository: self) }

    func save(_ alerts: StockAlerts) async throws {
        if whenItCannotKeep { throw CouldNotKeep() }
        subject.value = alerts
    }

    struct CouldNotKeep: Error {}

    private struct Session_: GetSessionUseCase, @unchecked Sendable {
        let repository: InMemoryStockAlertRepository

        @MainActor
        func callAsFunction() -> Session {
            guard repository.isSignedIn else { return .guest }
            return .authenticated(
                User(
                    id: UserID(rawValue: 42),
                    email: Email("shopper@example.com"),
                    name: PersonName(first: "Ada", last: nil)
                )
            )
        }
    }
}

@MainActor
final class StubAuthPresenter: AuthPresenting {
    private(set) var wasAsked = false
    var answer = false
    var onShown: (() -> Void)?

    func show(_ prompt: AuthenticationPrompt) async -> Bool {
        wasAsked = true
        onShown?()
        return answer
    }
}

@MainActor
final class RecordingSnackbarPresenter: SnackbarPresenting {
    private(set) var shown: [Snackbar] = []

    func show(_ snackbar: Snackbar) { shown.append(snackbar) }
}

@MainActor
final class StubNavigation: ProductActionsNavigation {
    private(set) var switchedToBagTab = false

    nonisolated func switchToBagTab() {
        MainActor.assumeIsolated { switchedToBagTab = true }
    }
}

// MARK: - Fixtures

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}

extension Product {
    static func fixture(
        id: Int,
        availability: Availability = .inStock(remaining: 10)
    ) -> Product {
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
