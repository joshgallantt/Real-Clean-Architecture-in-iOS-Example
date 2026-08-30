import Combine
import Money
import Order
import Product

@MainActor
public final class StubObserveOrders: ObserveOrdersUseCase {
    private let subject: CurrentValueSubject<Orders, Never>

    public init(_ orders: Orders = Orders()) {
        subject = CurrentValueSubject(orders)
    }

    public func callAsFunction() -> AnyPublisher<Orders, Never> { subject.eraseToAnyPublisher() }

    public func send(_ orders: Orders) { subject.send(orders) }
}
