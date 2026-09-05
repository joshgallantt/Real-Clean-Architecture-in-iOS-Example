import Combine
import Money
import Order
import Product

@MainActor
public final class FakeOrderRepository: OrderRepository {
    public init() {}

    private let subject = CurrentValueSubject<Orders, Never>(Orders())

    public var orders: Orders { subject.value }
    public var ordersPublisher: AnyPublisher<Orders, Never> { subject.eraseToAnyPublisher() }

    public func save(_ order: Order) {
        subject.value = subject.value.adding(order)
    }
}
