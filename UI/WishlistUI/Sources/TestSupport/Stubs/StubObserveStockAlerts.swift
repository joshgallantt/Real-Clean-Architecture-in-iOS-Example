import ProductTestSupport
import SnackbarUITestSupport
import Combine
import Money
import Product
import Session
import SessionTestSupport
import SnackbarUI
import StockAlert
@testable import WishlistUI

@MainActor
final class StubObserveStockAlerts {
    private let subject = CurrentValueSubject<StockAlerts, Never>(StockAlerts())

    func callAsFunction() -> AnyPublisher<StockAlerts, Never> { subject.eraseToAnyPublisher() }

    func send(_ alerts: StockAlerts) { subject.send(alerts) }
}
