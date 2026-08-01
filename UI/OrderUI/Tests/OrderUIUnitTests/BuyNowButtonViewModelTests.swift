import Foundation
import Testing
import Money
import Order
import Product
@testable import OrderUI

@MainActor
@Suite("Buy Now")
struct BuyNowButtonViewModelTests {
    private func makeViewModel(
        product: Product = .fixture(id: 1, price: 9.99),
        placeOrder: StubPlaceOrder = StubPlaceOrder(),
        authPresenter: StubAuthPresenter = StubAuthPresenter(),
        snackbarPresenter: SpySnackbarPresenter = SpySnackbarPresenter(),
        confirm: @escaping (Order) -> Void = { _ in }
    ) -> BuyNowButtonViewModel {
        BuyNowButtonViewModel(
            product: product,
            placeOrder: placeOrder,
            authPresenter: authPresenter,
            snackbarPresenter: snackbarPresenter,
            confirm: confirm
        )
    }

    @Test("Buying orders exactly one of the product on the page, at the price shown")
    func ordersOneOfWhatIsShown() async {
        let placeOrder = StubPlaceOrder()
        let viewModel = makeViewModel(product: .fixture(id: 1, price: 24.50), placeOrder: placeOrder)

        await viewModel.tapAndSettle()

        #expect(placeOrder.calls == [[OrderLine(productId: pid(1), quantity: 1, pricePaid: usd(24.50))]])
    }

    @Test("A successful order is handed to the confirmation callback")
    func confirmsOnSuccess() async {
        let placeOrder = StubPlaceOrder()
        let order = Order.fixture()
        placeOrder.result = .success(order)
        var confirmed: [Order] = []
        let viewModel = makeViewModel(placeOrder: placeOrder, confirm: { confirmed.append($0) })

        await viewModel.tapAndSettle()

        #expect(confirmed == [order])
    }

    @Test("A second tap while the first is still in flight is ignored")
    func ignoresASecondTapWhilePlacing() async {
        let placeOrder = StubPlaceOrder()
        placeOrder.holdTheNextOrderOpen()
        let viewModel = makeViewModel(placeOrder: placeOrder)

        viewModel.didTap()
        await yieldUntil { placeOrder.isHoldingAnOrderOpen }
        #expect(viewModel.isPlacing)

        viewModel.didTap()
        placeOrder.finishTheHeldOrder()
        await viewModel.settle()

        #expect(placeOrder.calls.count == 1)
    }

    @Test("A guest is asked to sign in, and buying resumes once they have")
    func guestIsAskedThenResumes() async {
        let placeOrder = StubPlaceOrder()
        placeOrder.result = .failure(.unauthenticated)
        let authPresenter = StubAuthPresenter(onSignIn: { placeOrder.result = .success(.fixture()) })
        authPresenter.signsIn = true
        var confirmed: [Order] = []
        let viewModel = makeViewModel(placeOrder: placeOrder, authPresenter: authPresenter, confirm: { confirmed.append($0) })

        await viewModel.tapAndSettle()

        #expect(authPresenter.timesAsked == 1)
        #expect(confirmed.count == 1)
    }

    @Test("A guest who backs out of signing in buys nothing, and is not nagged with a snackbar")
    func guestWhoBacksOutBuysNothing() async {
        let authPresenter = StubAuthPresenter()
        authPresenter.signsIn = false
        let placeOrder = StubPlaceOrder()
        placeOrder.result = .failure(.unauthenticated)
        var confirmed: [Order] = []
        let snackbarPresenter = SpySnackbarPresenter()
        let viewModel = makeViewModel(
            placeOrder: placeOrder,
            authPresenter: authPresenter,
            snackbarPresenter: snackbarPresenter,
            confirm: { confirmed.append($0) }
        )

        await viewModel.tapAndSettle()

        #expect(confirmed.isEmpty)
        #expect(snackbarPresenter.shown.isEmpty)
    }

    @Test("A declined payment says so, and nothing is confirmed")
    func declinedPaymentSaysSo() async {
        let placeOrder = StubPlaceOrder()
        placeOrder.result = .failure(.paymentDeclined)
        let snackbarPresenter = SpySnackbarPresenter()
        var confirmed: [Order] = []
        let viewModel = makeViewModel(placeOrder: placeOrder, snackbarPresenter: snackbarPresenter, confirm: { confirmed.append($0) })

        await viewModel.tapAndSettle()

        #expect(snackbarPresenter.shown.first?.title == "Payment Declined")
        #expect(confirmed.isEmpty)
    }

    @Test("The price shown is the price on the product, formatted")
    func priceLabelMatchesTheProduct() {
        let viewModel = makeViewModel(product: .fixture(id: 1, price: 24.50))

        #expect(viewModel.priceLabel == usd(24.50).formatted())
    }
}
