// Shared between this package's test suites. Xcode refuses a test target
// that depends on another test target, so code two suites both need has to
// be an ordinary module — marked visible to tests alone, which is what keeps
// it out of the app.

import ProductTestSupport
import SnackbarUITestSupport
import Combine
import Foundation
import Bag
import Money
import Order
import Product
import AuthUI
import SnackbarUI
@testable import OrderUI

@MainActor
final class StubPlaceOrder: PlaceOrderUseCase, @unchecked Sendable {
    var result: Result<Order, OrderError> = .success(.fixture())
    private(set) var calls: [[OrderLine]] = []

    private var holdsTheNextOrderOpen = false
    private var releaseTheHeldOrder: CheckedContinuation<Void, Never>?

    var isHoldingAnOrderOpen: Bool { releaseTheHeldOrder != nil }

    func holdTheNextOrderOpen() {
        holdsTheNextOrderOpen = true
    }

    func finishTheHeldOrder() {
        holdsTheNextOrderOpen = false
        releaseTheHeldOrder?.resume()
        releaseTheHeldOrder = nil
    }

    func callAsFunction(_ lines: [OrderLine]) async -> Result<Order, OrderError> {
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
final class StubAuthPresenter: AuthPresenting {
    var signsIn = false
    private(set) var timesAsked = 0
    private let onSignIn: () -> Void

    init(onSignIn: @escaping () -> Void = {}) {
        self.onSignIn = onSignIn
    }

    func show(_ prompt: AuthenticationPrompt) async -> Bool {
        timesAsked += 1
        if signsIn { onSignIn() }
        return signsIn
    }
}

@MainActor
final class StubObserveOrders: ObserveOrdersUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Orders, Never>

    init(_ orders: Orders = Orders()) {
        subject = CurrentValueSubject(orders)
    }

    func callAsFunction() -> AnyPublisher<Orders, Never> { subject.eraseToAnyPublisher() }

    func send(_ orders: Orders) { subject.send(orders) }
}

@MainActor
func yieldUntil(_ isSatisfied: () -> Bool) async {
    for _ in 0..<1_000 where !isSatisfied() { await Task.yield() }
}

@MainActor
extension BuyNowButtonViewModel {
    func tapAndSettle() async {
        didTap()
        await settle()
    }

    func settle() async {
        await yieldUntil { self.isPlacing }
        await yieldUntil { !self.isPlacing }
    }
}

@MainActor
extension CheckoutButtonViewModel {
    func tapAndSettle() async {
        didTap()
        await yieldUntil { self.isPlacing }
        await yieldUntil { !self.isPlacing }
    }
}

// MARK: - Fixtures

func usd(_ amount: Decimal) -> Money {
    Money(amount: amount, currency: .usd)
}

extension Order {
    static func fixture(lines: [OrderLine] = [OrderLine(productId: ProductID(rawValue: 1), pricePaid: Money(amount: 9.99, currency: .usd))]) -> Order {
        Order(lines: lines, paymentReference: PaymentReference(rawValue: "ref"))
    }
}
