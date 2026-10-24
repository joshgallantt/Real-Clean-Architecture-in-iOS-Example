import ProductTestSupport
import SnackbarUITestSupport
import Combine
import Money
import Product
import Session
import SessionTestSupport
import SnackbarUI
import Waitlist
@testable import WishlistUI

@MainActor
final class StubObserveStockAlerts {
    private let subject = CurrentValueSubject<Waitlist, Never>(Waitlist())

    func callAsFunction() -> AnyPublisher<Waitlist, Never> { subject.eraseToAnyPublisher() }

    func send(_ alerts: Waitlist) { subject.send(alerts) }
}
