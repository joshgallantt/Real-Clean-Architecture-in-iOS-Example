import AuthUITestSupport
import BagTestSupport
import Foundation
import MoneyTestSupport
import OrderTestSupport
import ProductTestSupport
import SnackbarUITestSupport
import Testing
import Bag
import Money
import Order
import Product
import Tracking
import TrackingUI
import TrackingTestSupport
@testable import OrderUI
@testable import OrderUITestSupport

@MainActor
@Suite("What ordering tells the shop")
/// A checkout is reported when it starts and a purchase only once there is an order: a payment
/// that was declined is a checkout that went nowhere, not a sale. Both are about the lines being
/// paid for, at the price being paid, wherever the button can name the product.
struct TrackingOrdersTests {
    private let screens = SpyTrackScreenViewUseCase()
    private let views = SpyTrackElementViewUseCase()
    private let taps = SpyTrackElementInteractionUseCase()
    private let reported = SpyTrackEventUseCase()
    private let setBagItem = SpySetBagItemUseCase()

    private let onTheProductPage = TrackingContext.screen("product_details")
    private let inTheBag = TrackingContext.screen("bag")

    private func buyNow(_ product: Product, placeOrder: SpyPlaceOrderUseCase, auth: SpyAuthPresenting) -> BuyNowButtonViewModel {
        BuyNowButtonViewModel(
            product: product,
            placeOrder: placeOrder,
            authPresenter: auth,
            snackbarPresenter: SpySnackbarPresenting(),
            confirm: { _ in },
            trackScreenView: screens,
            trackElementView: views,
            trackElementInteraction: taps,
            trackEvent: reported
        )
    }

    /// `products` is what the bag screen can name when it is asked, as the app hands it over.
    private func checkout(
        _ items: [BagItem],
        products: @escaping @MainActor () -> [ProductID: Product],
        placeOrder: SpyPlaceOrderUseCase
    ) -> CheckoutButtonViewModel {
        let viewModel = CheckoutButtonViewModel(
            observeBag: StubObserveBagUseCase(Bag(items: items)),
            placeOrder: placeOrder,
            setBagItem: setBagItem,
            authPresenter: SpyAuthPresenting(),
            snackbarPresenter: SpySnackbarPresenting(),
            confirm: { _ in },
            products: products,
            trackScreenView: screens,
            trackElementView: views,
            trackElementInteraction: taps,
            trackEvent: reported
        )
        viewModel.onAppear()
        return viewModel
    }

    /// An order whose id the test can name, so the event that carries it can be compared whole.
    private func placedOrder(_ id: String, lines: [OrderLine]) -> Order {
        Order(id: OrderID(rawValue: id), lines: lines, paymentReference: PaymentReference(rawValue: "ref"))
    }

    // MARK: - Buy Now

    @Test("Buying now is the tap, a checkout of that one product, then the purchase with the order's own id")
    func buyNowSucceeds() async {
        let product = Product.fixture(id: 1, price: 24.50)
        let placeOrder = SpyPlaceOrderUseCase()
        placeOrder.result = .success(placedOrder("A1B2", lines: [OrderLine(productId: pid(1), quantity: 1, pricePaid: usd(24.50))]))
        let viewModel = buyNow(product, placeOrder: placeOrder, auth: SpyAuthPresenting())

        viewModel.didTap(in: onTheProductPage)
        await viewModel.settle()

        let item = TrackedProduct.item(product)
        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: onTheProductPage, items: [item], properties: ["element": "buy_now"])])
        #expect(reported.events == [
            TrackingEvent(name: .checkoutStarted, context: onTheProductPage, items: [item], properties: [:]),
            TrackingEvent(name: .orderCompleted, context: onTheProductPage, items: [item], properties: ["order_id": "A1B2"])
        ])
    }

    @Test("The purchase is what the order holds of this product, at the price the order says was paid")
    func buyNowReportsWhatTheOrderHolds() async {
        let product = Product.fixture(id: 1, price: 24.50)
        let placeOrder = SpyPlaceOrderUseCase()
        placeOrder.result = .success(placedOrder("A1B2", lines: [
            OrderLine(productId: pid(1), quantity: 2, pricePaid: usd(20)),
            OrderLine(productId: pid(9), quantity: 1, pricePaid: usd(5))
        ]))
        let viewModel = buyNow(product, placeOrder: placeOrder, auth: SpyAuthPresenting())

        viewModel.didTap(in: onTheProductPage)
        await viewModel.settle()

        #expect(reported.events == [
            TrackingEvent(name: .checkoutStarted, context: onTheProductPage, items: [TrackedProduct.item(product)], properties: [:]),
            TrackingEvent(name: .orderCompleted, context: onTheProductPage, items: [TrackedProduct.item(product, price: usd(20), quantity: 2)], properties: ["order_id": "A1B2"])
        ])
    }

    @Test("An order holding none of this product is not reported as its purchase")
    func buyNowCannotNameAnotherProduct() async {
        let product = Product.fixture(id: 1)
        let placeOrder = SpyPlaceOrderUseCase()
        placeOrder.result = .success(placedOrder("A1B2", lines: [OrderLine(productId: pid(9), quantity: 1, pricePaid: usd(5))]))
        let viewModel = buyNow(product, placeOrder: placeOrder, auth: SpyAuthPresenting())

        viewModel.didTap(in: onTheProductPage)
        await viewModel.settle()

        #expect(reported.events == [TrackingEvent(name: .checkoutStarted, context: onTheProductPage, items: [TrackedProduct.item(product)], properties: [:])])
    }

    @Test("A declined payment is a checkout started and no purchase, with the snackbar it showed seen")
    func buyNowDeclined() async {
        let placeOrder = SpyPlaceOrderUseCase()
        placeOrder.result = .failure(.paymentDeclined)
        let viewModel = buyNow(.fixture(id: 1), placeOrder: placeOrder, auth: SpyAuthPresenting())

        viewModel.didTap(in: onTheProductPage)
        await viewModel.settle()

        let item = TrackedProduct.item(.fixture(id: 1))
        #expect(reported.events == [TrackingEvent(name: .checkoutStarted, context: onTheProductPage, items: [item], properties: [:])])
        #expect(views.events == [TrackingEvent(name: .elementViewed, context: onTheProductPage, items: [item], properties: ["element": "payment_declined"])])
    }

    @Test("Signing in part-way through is still the one tap and the one checkout, and the page behind the sheet is viewed again")
    func buyNowAfterSigningIn() async {
        let order = placedOrder("A1B2", lines: [OrderLine(productId: pid(1), quantity: 1, pricePaid: usd(9.99))])
        let placeOrder = SpyPlaceOrderUseCase()
        placeOrder.result = .failure(.unauthenticated)
        let auth = SpyAuthPresenting(onSignIn: { placeOrder.result = .success(order) })
        auth.signsIn = true
        let viewModel = buyNow(.fixture(id: 1, price: 9.99), placeOrder: placeOrder, auth: auth)

        viewModel.didTap(in: onTheProductPage)
        await viewModel.settle()

        let item = TrackedProduct.item(.fixture(id: 1, price: 9.99))
        #expect(taps.events.count == 1)
        #expect(reported.events == [
            TrackingEvent(name: .checkoutStarted, context: onTheProductPage, items: [item], properties: [:]),
            TrackingEvent(name: .orderCompleted, context: onTheProductPage, items: [item], properties: ["order_id": "A1B2"])
        ])
        #expect(screens.events == [TrackingEvent(name: .screenViewed, context: .screen("product_details"), items: [], properties: [:])])
    }

    // MARK: - Checking out

    @Test("Checking out reports the bag's lines as the bag keeps them, at the price being paid and not today's, then the purchase with the order's own id")
    func checkoutSucceeds() async {
        let lipstick = Product.fixture(id: 1, price: 12)
        /// The bag keeps its newest line first, so each line says when it went in.
        let lines = [
            BagItem(productId: pid(1), quantity: 2, lastKnownPrice: usd(9.99), dateAdded: Date(timeIntervalSince1970: 2)),
            BagItem(productId: pid(4), quantity: 1, lastKnownPrice: usd(5), dateAdded: Date(timeIntervalSince1970: 1))
        ]
        let order = placedOrder("A1B2", lines: lines.map { OrderLine(productId: $0.productId, quantity: $0.quantity, pricePaid: $0.lastKnownPrice) })
        let placeOrder = SpyPlaceOrderUseCase()
        placeOrder.result = .success(order)
        let viewModel = checkout(lines, products: { [pid(1): lipstick, pid(4): .fixture(id: 4)] }, placeOrder: placeOrder)

        viewModel.didTap(in: inTheBag)
        await viewModel.settle()

        let items = [
            TrackedProduct.item(lipstick, price: usd(9.99), quantity: 2),
            TrackedProduct.item(.fixture(id: 4), price: usd(5), quantity: 1)
        ]
        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: inTheBag, items: [], properties: ["element": "check_out"])])
        #expect(reported.events == [
            TrackingEvent(name: .checkoutStarted, context: inTheBag, items: items, properties: [:]),
            TrackingEvent(name: .orderCompleted, context: inTheBag, items: items, properties: ["order_id": "A1B2"])
        ])
    }

    @Test("A line the bag was not drawing a product for is left out of the checkout and of the purchase")
    func checkoutWithoutAnUnnamedLine() async {
        let lipstick = Product.fixture(id: 1, price: 12)
        let lines = [
            BagItem(productId: pid(1), quantity: 2, lastKnownPrice: usd(9.99)),
            BagItem(productId: pid(4), quantity: 1, lastKnownPrice: usd(5))
        ]
        let order = placedOrder("A1B2", lines: lines.map { OrderLine(productId: $0.productId, quantity: $0.quantity, pricePaid: $0.lastKnownPrice) })
        let placeOrder = SpyPlaceOrderUseCase()
        placeOrder.result = .success(order)
        let viewModel = checkout(lines, products: { [pid(1): lipstick] }, placeOrder: placeOrder)

        viewModel.didTap(in: inTheBag)
        await viewModel.settle()

        let item = TrackedProduct.item(lipstick, price: usd(9.99), quantity: 2)
        #expect(reported.events == [
            TrackingEvent(name: .checkoutStarted, context: inTheBag, items: [item], properties: [:]),
            TrackingEvent(name: .orderCompleted, context: inTheBag, items: [item], properties: ["order_id": "A1B2"])
        ])
    }

    @Test("Lines nobody can name are not a checkout, and the order they become is not a purchase")
    func nothingNameable() async {
        let viewModel = checkout([BagItem(productId: pid(1), lastKnownPrice: usd(1))], products: { [:] }, placeOrder: SpyPlaceOrderUseCase())

        viewModel.didTap(in: inTheBag)
        await viewModel.settle()

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: inTheBag, items: [], properties: ["element": "check_out"])])
        #expect(reported.events.isEmpty)
    }

    @Test("A checkout that did not go through is not a purchase")
    func checkoutFails() async {
        let placeOrder = SpyPlaceOrderUseCase()
        placeOrder.result = .failure(.unavailable)
        let viewModel = checkout([BagItem(productId: pid(1), lastKnownPrice: usd(1))], products: { [pid(1): .fixture(id: 1)] }, placeOrder: placeOrder)

        viewModel.didTap(in: inTheBag)
        await viewModel.settle()

        let item = TrackedProduct.item(.fixture(id: 1), price: usd(1), quantity: 1)
        #expect(reported.events == [TrackingEvent(name: .checkoutStarted, context: inTheBag, items: [item], properties: [:])])
        #expect(views.events == [TrackingEvent(name: .elementViewed, context: inTheBag, items: [], properties: ["element": "that_didn_t_go_through"])])
    }

    @Test("The purchase is named before the bag is emptied, while the bag screen can still say what was in it")
    func purchaseIsNamedBeforeTheBagEmpties() async {
        let placeOrder = SpyPlaceOrderUseCase()
        placeOrder.result = .success(placedOrder("A1B2", lines: [OrderLine(productId: pid(1), quantity: 1, pricePaid: usd(1))]))
        /// A bag screen stops drawing a product once its line has gone.
        let emptied = setBagItem
        let viewModel = checkout(
            [BagItem(productId: pid(1), lastKnownPrice: usd(1))],
            products: { emptied.calls.isEmpty ? [pid(1): .fixture(id: 1)] : [:] },
            placeOrder: placeOrder
        )

        viewModel.didTap(in: inTheBag)
        await viewModel.settle()

        let item = TrackedProduct.item(.fixture(id: 1), price: usd(1), quantity: 1)
        #expect(emptied.calls.map(\.productId) == [pid(1)])
        #expect(reported.events == [
            TrackingEvent(name: .checkoutStarted, context: inTheBag, items: [item], properties: [:]),
            TrackingEvent(name: .orderCompleted, context: inTheBag, items: [item], properties: ["order_id": "A1B2"])
        ])
    }

    // MARK: - The screens

    @Test("Order history reports its screen every time it comes into view")
    func historyScreen() {
        let viewModel = OrderHistoryViewModel(observeOrders: StubObserveOrdersUseCase(), trackScreenView: screens)
        let history = TrackingContext.screen("order_history")

        viewModel.didAppear(in: history)
        viewModel.didAppear(in: history)

        #expect(screens.events == [TrackingEvent(name: .screenViewed, context: .screen("order_history"), items: [], properties: [:]), TrackingEvent(name: .screenViewed, context: .screen("order_history"), items: [], properties: [:])])
    }

    @Test("The confirmation reports its screen, and Done as a tap on it")
    func confirmation() {
        var dismissed = false
        let viewModel = OrderConfirmationViewModel(
            order: OrderSummary(.fixture()),
            done: { dismissed = true },
            trackScreenView: screens,
            trackElementInteraction: taps
        )
        let confirmation = TrackingContext.screen("order_confirmation")

        viewModel.didAppear(in: confirmation)
        viewModel.didTapDone(in: confirmation)

        #expect(screens.events == [TrackingEvent(name: .screenViewed, context: .screen("order_confirmation"), items: [], properties: [:])])
        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: confirmation, items: [], properties: ["element": "done"])])
        #expect(dismissed)
    }
}
