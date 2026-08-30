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
final class StubObserveSavedProductIds {
    private let subject: CurrentValueSubject<[ProductID], Never>

    init(_ ids: [ProductID] = []) {
        subject = CurrentValueSubject(ids)
    }

    func callAsFunction() -> AnyPublisher<[ProductID], Never> { subject.eraseToAnyPublisher() }

    func send(_ ids: [ProductID]) { subject.send(ids) }
}
