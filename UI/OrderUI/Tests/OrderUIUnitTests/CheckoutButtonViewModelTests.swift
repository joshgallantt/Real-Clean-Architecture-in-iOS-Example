import Foundation
import Testing
import Bag
import Money
import Order
import Product
@testable import OrderUI

@MainActor
@Suite("Checking out")
struct CheckoutButtonViewModelTests {
    private func makeViewModel(
        observeBag: StubObserveBag = StubObserveBag(),
        placeOrder: StubPlaceOrder = StubPlaceOrder(),
        setBagItemQuantity: SpySetBagItemQuantity = SpySetBagItemQuantity(),
        authPresenter: StubAuthPresenter = StubAuthPresenter(),
        snackbarPresenter: SpySnackbarPresenter = SpySnackbarPresenter(),
        confirm: @escaping (Order) -> Void = { _ in }
    ) -> CheckoutButtonViewModel {
        CheckoutButtonViewModel(
            observeBag: observeBag,
            placeOrder: placeOrder,
            setBagItemQuantity: setBagItemQuantity,
            authPresenter: authPresenter,
            snackbarPresenter: snackbarPresenter,
            confirm: confirm
        )
    }

    private func bag(_ items: BagItem...) -> Bag { Bag(items: items) }

    @Test("Checking out orders every line in the bag, at the prices it was showing")
    func ordersEveryLine() async {
        let observeBag = StubObserveBag(bag(
            BagItem(productId: pid(1), quantity: 2, lastKnownPrice: usd(9.99), dateAdded: .now),
            BagItem(productId: pid(2), quantity: 1, lastKnownPrice: usd(5), dateAdded: .distantPast)
        ))
        let placeOrder = StubPlaceOrder()
        let viewModel = makeViewModel(observeBag: observeBag, placeOrder: placeOrder)

        await viewModel.tapAndSettle()

        #expect(placeOrder.calls == [[
            OrderLine(productId: pid(1), quantity: 2, pricePaid: usd(9.99)),
            OrderLine(productId: pid(2), quantity: 1, pricePaid: usd(5))
        ]])
    }

    @Test("A successful checkout empties every line that was ordered")
    func emptiesEveryLineOnSuccess() async {
        let observeBag = StubObserveBag(bag(
            BagItem(productId: pid(1), quantity: 2, lastKnownPrice: usd(9.99)),
            BagItem(productId: pid(2), quantity: 1, lastKnownPrice: usd(5))
        ))
        let setBagItemQuantity = SpySetBagItemQuantity()
        let viewModel = makeViewModel(observeBag: observeBag, setBagItemQuantity: setBagItemQuantity)

        await viewModel.tapAndSettle()

        #expect(Set(setBagItemQuantity.calls.map(\.productId)) == Set([pid(1), pid(2)]))
        #expect(setBagItemQuantity.calls.allSatisfy { $0.quantity == 0 })
    }

    @Test("A declined payment leaves the bag exactly as it was")
    func declinedLeavesTheBag() async {
        let observeBag = StubObserveBag(bag(BagItem(productId: pid(1), quantity: 2, lastKnownPrice: usd(9.99))))
        let placeOrder = StubPlaceOrder()
        placeOrder.result = .failure(.paymentDeclined)
        let setBagItemQuantity = SpySetBagItemQuantity()
        let snackbarPresenter = SpySnackbarPresenter()
        let viewModel = makeViewModel(
            observeBag: observeBag,
            placeOrder: placeOrder,
            setBagItemQuantity: setBagItemQuantity,
            snackbarPresenter: snackbarPresenter
        )

        await viewModel.tapAndSettle()

        #expect(setBagItemQuantity.calls.isEmpty)
        #expect(snackbarPresenter.shown.first?.title == "Payment Declined")
    }

    @Test("An empty bag has nothing to check out")
    func emptyBagHasNothingToCheckOut() {
        let viewModel = makeViewModel()

        #expect(viewModel.isEmpty)
    }

    @Test("The total shown is what the bag is worth, formatted")
    func totalLabelMatchesTheBag() {
        let observeBag = StubObserveBag(bag(BagItem(productId: pid(1), quantity: 2, lastKnownPrice: usd(10))))
        let viewModel = makeViewModel(observeBag: observeBag)

        #expect(viewModel.totalLabel == usd(20).formatted())
        #expect(viewModel.isEmpty == false)
    }

    @Test("A guest who backs out of signing in keeps their bag, and checks out nothing")
    func guestWhoBacksOutKeepsTheBag() async {
        let observeBag = StubObserveBag(bag(BagItem(productId: pid(1), quantity: 1, lastKnownPrice: usd(9.99))))
        let placeOrder = StubPlaceOrder()
        placeOrder.result = .failure(.unauthenticated)
        let authPresenter = StubAuthPresenter()
        authPresenter.signsIn = false
        let setBagItemQuantity = SpySetBagItemQuantity()
        let viewModel = makeViewModel(
            observeBag: observeBag,
            placeOrder: placeOrder,
            setBagItemQuantity: setBagItemQuantity,
            authPresenter: authPresenter
        )

        await viewModel.tapAndSettle()

        #expect(authPresenter.timesAsked == 1)
        #expect(setBagItemQuantity.calls.isEmpty)
    }

    @Test("A bag with nothing in it says so, rather than being sent to the till")
    func nothingToOrderSaysSo() async {
        let placeOrder = StubPlaceOrder()
        placeOrder.result = .failure(.nothingToOrder)
        let snackbarPresenter = SpySnackbarPresenter()
        let viewModel = makeViewModel(placeOrder: placeOrder, snackbarPresenter: snackbarPresenter)

        await viewModel.tapAndSettle()

        #expect(snackbarPresenter.shown.first?.title == "Nothing in Your Bag")
    }
}
