import Foundation
import Testing
import Order
@testable import OrderUI

@MainActor
@Suite("Order history")
struct OrderHistoryViewModelTests {
    @Test("A shopper with no orders has an empty history")
    func noOrdersIsEmpty() {
        let viewModel = OrderHistoryViewModel(observeOrders: StubObserveOrders())

        #expect(viewModel.isEmpty)
        #expect(viewModel.orders.isEmpty)
    }

    @Test("History shows whatever the use case is already holding when the screen appears")
    func showsWhatIsAlreadyThere() {
        let order = Order.fixture()
        let viewModel = OrderHistoryViewModel(observeOrders: StubObserveOrders(Orders([order])))

        #expect(viewModel.orders == [order])
        #expect(viewModel.isEmpty == false)
    }

    @Test("An order placed after the screen appeared shows up too")
    func showsAnOrderPlacedLater() {
        let observeOrders = StubObserveOrders()
        let viewModel = OrderHistoryViewModel(observeOrders: observeOrders)

        observeOrders.send(Orders([.fixture()]))

        #expect(viewModel.orders.count == 1)
    }
}
