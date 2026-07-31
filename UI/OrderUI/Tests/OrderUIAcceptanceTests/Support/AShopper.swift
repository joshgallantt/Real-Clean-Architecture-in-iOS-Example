import Combine
import Foundation
import Bag
import Money
import Order
import Product
import Session
import AuthUI
import SnackbarUI
@testable import OrderUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. Tests say what
/// a shopper tapped and what happened, never which type held it.
///
/// Only three things are stood in for, and each is something the app genuinely cannot own: where
/// orders are kept, who takes the money, and what a sign-in prompt answers. The use cases the
/// buttons are handed are the real ones, built over these.
final class AShopper {
    let orders = InMemoryOrderRepository()
    let bag = InMemoryBagRepository()
    let till = StubPaymentClient()
    let snackbars = SpySnackbarPresenter()

    /// Signing in at the prompt actually signs them in, so the retry that follows behaves the way
    /// it would in the app rather than looping.
    private(set) lazy var signIn = StubAuthPresenter { [weak self] in self?.isSignedIn = true }

    private(set) var confirmed: [Order] = []

    var isSignedIn = true

    // MARK: - The real use cases, over the doubles

    private var placeOrder: PlaceOrderUseCase {
        DefaultPlaceOrderUseCase(
            repository: orders,
            payment: till,
            getSession: StubGetSession(shopper: self)
        )
    }

    // MARK: - The buttons a shopper can tap

    func buyNowButton(for product: Product) -> BuyNowButtonViewModel {
        BuyNowButtonViewModel(
            product: product,
            placeOrder: placeOrder,
            authPresenter: signIn,
            snackbarPresenter: snackbars,
            confirm: { [weak self] in self?.confirmed.append($0) }
        )
    }

    func checkoutButton() -> CheckoutButtonViewModel {
        CheckoutButtonViewModel(
            observeBag: DefaultObserveBagUseCase(repository: bag),
            placeOrder: placeOrder,
            setBagItemQuantity: DefaultSetBagItemQuantityUseCase(repository: bag),
            authPresenter: signIn,
            snackbarPresenter: snackbars,
            confirm: { [weak self] in self?.confirmed.append($0) }
        )
    }

    // MARK: - What is already true when they arrive

    func putInBag(_ id: Int, quantity: Int = 1, at price: Decimal) {
        bag.save(
            bag: bag.bag.adding(
                BagItem(productId: pid(id), quantity: quantity, lastKnownPrice: usd(price))
            ),
            notices: bag.notices
        )
    }
}

// MARK: - What the app cannot own

@MainActor
final class InMemoryOrderRepository: OrderRepository {
    private let subject = CurrentValueSubject<Orders, Never>(Orders())

    var orders: Orders { subject.value }
    var ordersPublisher: AnyPublisher<Orders, Never> { subject.eraseToAnyPublisher() }

    func save(_ order: Order) {
        subject.value = subject.value.adding(order)
    }
}

@MainActor
/// A working repository rather than a stub with canned answers, so the real bag use cases genuinely
/// read, apply and save.
final class InMemoryBagRepository: BagRepository {
    private let bagSubject = CurrentValueSubject<Bag, Never>(Bag())
    private let noticesSubject = CurrentValueSubject<Notices, Never>(Notices())

    var bag: Bag { bagSubject.value }
    var bagPublisher: AnyPublisher<Bag, Never> { bagSubject.eraseToAnyPublisher() }
    var notices: Notices { noticesSubject.value }
    var noticesPublisher: AnyPublisher<Notices, Never> { noticesSubject.eraseToAnyPublisher() }

    func save(bag: Bag, notices: Notices) {
        bagSubject.value = bag
        noticesSubject.value = notices
    }
}

final class StubPaymentClient: PaymentClient, @unchecked Sendable {
    private let lock = NSLock()
    private var _outcome: Result<PaymentReference, PaymentFailure> = .success(PaymentReference(rawValue: "ref"))
    private var _amountsAskedFor: [Money] = []

    var outcome: Result<PaymentReference, PaymentFailure> {
        get { lock.withLock { _outcome } }
        set { lock.withLock { _outcome = newValue } }
    }

    var amountsAskedFor: [Money] { lock.withLock { _amountsAskedFor } }

    var timesAsked: Int { amountsAskedFor.count }

    func pay(_ amount: Money) async -> Result<PaymentReference, PaymentFailure> {
        lock.withLock {
            _amountsAskedFor.append(amount)
            return _outcome
        }
    }
}

@MainActor
/// Answers the prompt the way the shopper would. `signsIn` is what they do when asked.
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

    func show(_ snackbar: Snackbar) { shown.append(snackbar) }
}

private struct StubGetSession: GetSessionUseCase, @unchecked Sendable {
    let shopper: AShopper

    @MainActor
    func callAsFunction() -> Session {
        guard shopper.isSignedIn else { return .guest }
        return .authenticated(
            User(
                id: UserID(rawValue: 1),
                email: Email("shopper@example.com"),
                name: PersonName(first: "Ada", last: nil)
            )
        )
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
