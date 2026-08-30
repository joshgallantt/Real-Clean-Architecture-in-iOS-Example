// Stand-ins for the protocols this package declares, so that every suite
// needing one shares a single definition rather than writing its own.

import Combine
import Foundation
import Money
import Order
import Product

@MainActor
public final class StubPlaceOrder: PlaceOrderUseCase, @unchecked Sendable {
    public init() {}

    public var result: Result<Order, OrderError> = .success(.fixture())
    public private(set) var calls: [[OrderLine]] = []

    private var holdsTheNextOrderOpen = false
    private var releaseTheHeldOrder: CheckedContinuation<Void, Never>?

    public var isHoldingAnOrderOpen: Bool { releaseTheHeldOrder != nil }

    public func holdTheNextOrderOpen() {
        holdsTheNextOrderOpen = true
    }

    public func finishTheHeldOrder() {
        holdsTheNextOrderOpen = false
        releaseTheHeldOrder?.resume()
        releaseTheHeldOrder = nil
    }

    public func callAsFunction(_ lines: [OrderLine]) async -> Result<Order, OrderError> {
        calls.append(lines)

        if holdsTheNextOrderOpen {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                releaseTheHeldOrder = continuation
            }
        }

        return result
    }
}

@MainActor
public final class StubObserveOrders: ObserveOrdersUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Orders, Never>

    public init(_ orders: Orders = Orders()) {
        subject = CurrentValueSubject(orders)
    }

    public func callAsFunction() -> AnyPublisher<Orders, Never> { subject.eraseToAnyPublisher() }

    public func send(_ orders: Orders) { subject.send(orders) }
}

@MainActor
public final class InMemoryOrderRepository: OrderRepository {
    public init() {}

    private let subject = CurrentValueSubject<Orders, Never>(Orders())

    public var orders: Orders { subject.value }
    public var ordersPublisher: AnyPublisher<Orders, Never> { subject.eraseToAnyPublisher() }

    public func save(_ order: Order) {
        subject.value = subject.value.adding(order)
    }
}

public final class StubPaymentService: PaymentService, @unchecked Sendable {
    public init() {}

    private let lock = NSLock()
    private var _outcome: Result<PaymentReference, PaymentFailure> = .success(PaymentReference(rawValue: "ref"))
    private var _amountsAskedFor: [Money] = []

    public var outcome: Result<PaymentReference, PaymentFailure> {
        get { lock.withLock { _outcome } }
        set { lock.withLock { _outcome = newValue } }
    }

    public var amountsAskedFor: [Money] { lock.withLock { _amountsAskedFor } }

    public var timesAsked: Int { amountsAskedFor.count }

    public func pay(_ amount: Money) async -> Result<PaymentReference, PaymentFailure> {
        lock.withLock {
            _amountsAskedFor.append(amount)
            return _outcome
        }
    }
}

extension Order {
    public static func fixture(lines: [OrderLine] = [OrderLine(productId: ProductID(rawValue: 1), pricePaid: Money(amount: 9.99, currency: .usd))]) -> Order {
        Order(lines: lines, paymentReference: PaymentReference(rawValue: "ref"))
    }
}
