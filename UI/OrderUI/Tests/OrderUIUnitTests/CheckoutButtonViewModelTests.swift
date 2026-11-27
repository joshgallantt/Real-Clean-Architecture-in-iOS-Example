import MoneyTestSupport
import AuthUITestSupport
import BagTestSupport
import Foundation
import OrderTestSupport
import ProductTestSupport
import SnackbarUITestSupport
import Testing
import Tracking
import TrackingTestSupport
import Bag
import Money
import Order
import Product
@testable import OrderUI
@testable import OrderUITestSupport

@MainActor
@Suite("Checking out")
struct CheckoutButtonViewModelTests {
    private func makeViewModel(
        bag: Bag = Bag(),
        placeOrder: SpyPlaceOrderUseCase = SpyPlaceOrderUseCase(),
        setBagItem: SpySetBagItemUseCase = SpySetBagItemUseCase(),
        authPresenter: SpyAuthPresenting = SpyAuthPresenting(),
        snackbarPresenter: SpySnackbarPresenting = SpySnackbarPresenting(),
        confirm: @escaping (Order) -> Void = { _ in }
    ) -> CheckoutButtonViewModel {
        CheckoutButtonViewModel(
            bag: { bag },
            placeOrder: placeOrder,
            setBagItem: setBagItem,
            authPresenter: authPresenter,
            snackbarPresenter: snackbarPresenter,
            confirm: confirm,
            products: { [:] },
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementView: SpyTrackElementViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase(),
            trackEvent: SpyTrackEventUseCase()
        )
    }

    private func bag(_ items: BagItem...) -> Bag { Bag(items: items) }

    @Test("Checking out orders every line in the bag, at the prices it was showing")
    func ordersEveryLine() async {
        let drawn = bag(
            BagItem(productId: pid(1), quantity: 2, lastKnownPrice: usd(9.99), dateAdded: .now),
            BagItem(productId: pid(2), quantity: 1, lastKnownPrice: usd(5), dateAdded: .distantPast)
        )
        let placeOrder = SpyPlaceOrderUseCase()
        let viewModel = makeViewModel(bag: drawn, placeOrder: placeOrder)

        await viewModel.tapAndSettle()

        #expect(placeOrder.calls == [[
            OrderLine(productId: pid(1), quantity: 2, pricePaid: usd(9.99)),
            OrderLine(productId: pid(2), quantity: 1, pricePaid: usd(5))
        ]])
    }

    @Test("What is ordered is the bag as it is drawn when the button is tapped, not as it was when the button was made")
    func ordersTheBagAsItIsWhenTapped() async {
        let screen = FakeBagRepository(bag: bag(BagItem(productId: pid(1), quantity: 1, lastKnownPrice: usd(9.99), dateAdded: .now)))
        let placeOrder = SpyPlaceOrderUseCase()
        let viewModel = CheckoutButtonViewModel(
            bag: { screen.bag },
            placeOrder: placeOrder,
            setBagItem: SpySetBagItemUseCase(),
            authPresenter: SpyAuthPresenting(),
            snackbarPresenter: SpySnackbarPresenting(),
            confirm: { _ in },
            products: { [:] },
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementView: SpyTrackElementViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase(),
            trackEvent: SpyTrackEventUseCase()
        )

        screen.save(bag(BagItem(productId: pid(1), quantity: 2, lastKnownPrice: usd(12.99), dateAdded: .now)))
        await viewModel.tapAndSettle()

        #expect(placeOrder.calls == [[OrderLine(productId: pid(1), quantity: 2, pricePaid: usd(12.99))]])
        #expect(viewModel.totalLabel == usd(25.98).formatted())
    }

    @Test("A successful checkout empties every line that was ordered")
    func emptiesEveryLineOnSuccess() async {
        let drawn = bag(
            BagItem(productId: pid(1), quantity: 2, lastKnownPrice: usd(9.99)),
            BagItem(productId: pid(2), quantity: 1, lastKnownPrice: usd(5))
        )
        let setBagItem = SpySetBagItemUseCase()
        let viewModel = makeViewModel(bag: drawn, setBagItem: setBagItem)

        await viewModel.tapAndSettle()

        #expect(Set(setBagItem.calls.map(\.productId)) == Set([pid(1), pid(2)]))
        #expect(setBagItem.calls.allSatisfy { $0.quantity == 0 })
    }

    @Test("A declined payment leaves the bag exactly as it was")
    func declinedLeavesTheBag() async {
        let drawn = bag(BagItem(productId: pid(1), quantity: 2, lastKnownPrice: usd(9.99)))
        let placeOrder = SpyPlaceOrderUseCase()
        placeOrder.result = .failure(.paymentDeclined)
        let setBagItem = SpySetBagItemUseCase()
        let snackbarPresenter = SpySnackbarPresenting()
        let viewModel = makeViewModel(
            bag: drawn,
            placeOrder: placeOrder,
            setBagItem: setBagItem,
            snackbarPresenter: snackbarPresenter
        )

        await viewModel.tapAndSettle()

        #expect(setBagItem.calls.isEmpty)
        #expect(snackbarPresenter.shown.first?.title == "Payment Declined")
    }

    @Test("An empty bag has nothing to check out")
    func emptyBagHasNothingToCheckOut() {
        let viewModel = makeViewModel()

        #expect(viewModel.isEmpty)
    }

    @Test("The total shown is what the bag is worth, formatted")
    func totalLabelMatchesTheBag() {
        let drawn = bag(BagItem(productId: pid(1), quantity: 2, lastKnownPrice: usd(10)))
        let viewModel = makeViewModel(bag: drawn)

        #expect(viewModel.totalLabel == usd(20).formatted())
        #expect(viewModel.isEmpty == false)
    }

    @Test("A guest who backs out of signing in keeps their bag, and checks out nothing")
    func guestWhoBacksOutKeepsTheBag() async {
        let drawn = bag(BagItem(productId: pid(1), quantity: 1, lastKnownPrice: usd(9.99)))
        let placeOrder = SpyPlaceOrderUseCase()
        placeOrder.result = .failure(.unauthenticated)
        let authPresenter = SpyAuthPresenting()
        authPresenter.signsIn = false
        let setBagItem = SpySetBagItemUseCase()
        let viewModel = makeViewModel(
            bag: drawn,
            placeOrder: placeOrder,
            setBagItem: setBagItem,
            authPresenter: authPresenter
        )

        await viewModel.tapAndSettle()

        #expect(authPresenter.timesAsked == 1)
        #expect(setBagItem.calls.isEmpty)
    }

    @Test("A bag with nothing in it says so, rather than being sent to the till")
    func nothingToOrderSaysSo() async {
        let placeOrder = SpyPlaceOrderUseCase()
        placeOrder.result = .failure(.nothingToOrder)
        let snackbarPresenter = SpySnackbarPresenting()
        let viewModel = makeViewModel(placeOrder: placeOrder, snackbarPresenter: snackbarPresenter)

        await viewModel.tapAndSettle()

        #expect(snackbarPresenter.shown.first?.title == "Nothing in Your Bag")
    }
}
