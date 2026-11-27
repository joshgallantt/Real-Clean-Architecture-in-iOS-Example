import MoneyTestSupport
import AuthUITestSupport
import BagTestSupport
import OrderTestSupport
import ProductTestSupport
import SessionTestSupport
import SnackbarUITestSupport
import Combine
import Foundation
import Tracking
import TrackingTestSupport
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
/// Only four things are stood in for, and each is something the app genuinely cannot own: where
/// orders are kept, who takes the money, what a sign-in prompt answers, and what the shop sells
/// today. The use cases the buttons are handed are the real ones, built over these.
final class AShopper {
    let orders = FakeOrderRepository()
    let bag = FakeBagRepository()
    let till = SpyPaymentService()
    let shop = FakeLookUpProductsUseCase()
    let snackbars = SpySnackbarPresenting()

    /// Signing in at the prompt actually signs them in, so the retry that follows behaves the way
    /// it would in the app rather than looping.
    private(set) lazy var signIn = SpyAuthPresenting { [weak self] in self?.isSignedIn = true }

    private(set) var confirmed: [Order] = []

    /// What the shop said the last time they looked in their bag. Nothing, until they look.
    private var shopSaid = Bag().checked(against: [], asked: [])

    /// Held in the shared session stub rather than in a stub of this driver's
    /// own, so that "who is signed in" is one fact with one representation
    /// across every suite that asks about it.
    var isSignedIn: Bool {
        get { sessions.session != .guest }
        set { sessions.session = newValue ? .authenticated(AShopper.shopper) : .guest }
    }

    private let sessions = StubGetSessionUseCase(.authenticated(AShopper.shopper))

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
            confirm: { [weak self] in self?.confirmed.append($0) },
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementView: SpyTrackElementViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase(),
            trackEvent: SpyTrackEventUseCase()
        )
    }

    /// Handed the bag as the bag screen draws it, the way the app hands it over: the bag that is
    /// kept, held against whatever the shop last said.
    func checkoutButton() -> CheckoutButtonViewModel {
        CheckoutButtonViewModel(
            bag: { [unowned self] in bagOnScreen },
            placeOrder: placeOrder,
            setBagItem: DefaultSetBagItemUseCase(repository: bag),
            authPresenter: signIn,
            snackbarPresenter: snackbars,
            confirm: { [weak self] in self?.confirmed.append($0) },
            products: { [:] },
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementView: SpyTrackElementViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase(),
            trackEvent: SpyTrackEventUseCase()
        )
    }

    private var bagOnScreen: Bag {
        bag.bag.checked(against: shopSaid.products, asked: shopSaid.asked).bag
    }

    // MARK: - What is already true when they arrive

    func putInBag(_ id: Int, quantity: Int = 1, at price: Decimal) {
        bag.save(
            bag.bag.setting(
                BagItem(productId: pid(id), quantity: quantity, lastKnownPrice: usd(price))
            )
        )
    }

    // MARK: - What the shop does, and the shopper seeing it

    func theShopNowSells(_ products: Product...) {
        shop.stock = products.map(OnTheShelf.init(product:))
    }

    /// They open their bag, and it is checked against the shop — by the real use case. Nothing is
    /// kept: the bag that is stored is still the one they saw last time.
    func looksInTheirBag() async {
        shopSaid = await DefaultCheckBagUseCase(repository: bag, lookUpProducts: shop)()
    }
}

// MARK: - What the app cannot own

// MARK: - Fixtures

