import MoneyTestSupport
import AuthUITestSupport
import BagTestSupport
import OrderTestSupport
import ProductTestSupport
import SessionTestSupport
import SnackbarUITestSupport
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
    let till = StubPaymentService()
    let snackbars = SpySnackbarPresenter()

    /// Signing in at the prompt actually signs them in, so the retry that follows behaves the way
    /// it would in the app rather than looping.
    private(set) lazy var signIn = StubAuthPresenter { [weak self] in self?.isSignedIn = true }

    private(set) var confirmed: [Order] = []

    /// Held in the shared session stub rather than in a stub of this driver's
    /// own, so that "who is signed in" is one fact with one representation
    /// across every suite that asks about it.
    var isSignedIn: Bool {
        get { sessions.session != .guest }
        set { sessions.session = newValue ? .authenticated(AShopper.shopper) : .guest }
    }

    private let sessions = StubGetSession(.authenticated(AShopper.shopper))

    private static let shopper = User(
        id: UserID(rawValue: 1),
        email: Email("shopper@example.com"),
        name: PersonName(first: "Ada", last: nil)
    )

    // MARK: - The real use cases, over the doubles

    private var placeOrder: PlaceOrderUseCase {
        DefaultPlaceOrderUseCase(
            repository: orders,
            payment: till,
            getSession: sessions
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

// MARK: - Fixtures

