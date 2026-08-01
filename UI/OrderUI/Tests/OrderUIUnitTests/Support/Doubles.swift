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
final class SpySnackbarPresenter: SnackbarPresenting {
    private(set) var shown: [Snackbar] = []

    func show(_ snackbar: Snackbar) {
        shown.append(snackbar)
    }
}

@MainActor
final class StubObserveBag: ObserveBagUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Bag, Never>

    init(_ bag: Bag = Bag()) {
        subject = CurrentValueSubject(bag)
    }

    func callAsFunction() -> AnyPublisher<Bag, Never> { subject.eraseToAnyPublisher() }
}

@MainActor
final class SpySetBagItemQuantity: SetBagItemQuantityUseCase, @unchecked Sendable {
    private(set) var calls: [(productId: ProductID, quantity: Int)] = []

    func callAsFunction(productId: ProductID, to quantity: Int) {
        calls.append((productId, quantity))
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

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}

func usd(_ amount: Decimal) -> Money {
    Money(amount: amount, currency: .usd)
}

extension Product {
    static func fixture(id: Int, price: Decimal = 9.99) -> Product {
        Product(
            id: pid(id),
            title: "Product \(id)",
            description: "",
            category: CategoryID(rawValue: "beauty"),
            price: usd(price),
            rating: 4.5,
            availability: .inStock(remaining: 10),
            brand: "Acme",
            thumbnail: "https://cdn.example.com/\(id).png",
            images: []
        )
    }
}

extension Order {
    static func fixture(lines: [OrderLine] = [OrderLine(productId: ProductID(rawValue: 1), pricePaid: Money(amount: 9.99, currency: .usd))]) -> Order {
        Order(lines: lines, paymentReference: PaymentReference(rawValue: "ref"))
    }
}
