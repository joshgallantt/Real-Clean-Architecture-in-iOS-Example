// Shared between this package's test suites. Xcode refuses a test target
// that depends on another test target, so code two suites both need has to
// be an ordinary module — marked visible to tests alone, which is what keeps
// it out of the app.

import ProductTestSupport
import SnackbarUITestSupport
import Combine
import Foundation
import Money
import Product
import Session
import SessionTestSupport
import SnackbarUI
import StockAlert
@testable import WishlistUI

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
func settle() async {
    for _ in 0..<200 { await Task.yield() }
}

// MARK: - Fixtures

extension User {
    static func fixture() -> User {
        User(id: UserID(rawValue: 1), email: Email("ada@example.com"), name: PersonName(first: "Ada", last: nil))
    }
}
