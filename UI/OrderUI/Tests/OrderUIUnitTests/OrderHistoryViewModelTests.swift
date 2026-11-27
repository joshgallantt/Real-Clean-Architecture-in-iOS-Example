import Foundation
import OrderTestSupport
import Testing
import Tracking
import TrackingTestSupport
import Order
@testable import OrderUI

@MainActor
@Suite("Order history")
struct OrderHistoryViewModelTests {
    @Test("A shopper with no orders has an empty history")
    func noOrdersIsEmpty() {
        let viewModel = OrderHistoryViewModel(observeOrders: StubObserveOrdersUseCase(), trackScreenView: SpyTrackScreenViewUseCase())
        viewModel.onAppear()

        #expect(viewModel.isEmpty)
        #expect(viewModel.orders.isEmpty)
    }

    @Test("History shows whatever the use case is already holding when the screen appears")
    func showsWhatIsAlreadyThere() {
        let order = Order.fixture()
        let viewModel = OrderHistoryViewModel(observeOrders: StubObserveOrdersUseCase(Orders([order])), trackScreenView: SpyTrackScreenViewUseCase())
        viewModel.onAppear()

        #expect(viewModel.orders == [OrderSummary(order)])
        #expect(viewModel.isEmpty == false)
    }

    @Test("An order placed after the screen appeared shows up too")
    func showsAnOrderPlacedLater() {
        let observeOrders = StubObserveOrdersUseCase()
        let viewModel = OrderHistoryViewModel(observeOrders: observeOrders, trackScreenView: SpyTrackScreenViewUseCase())
        viewModel.onAppear()

        observeOrders.send(Orders([.fixture()]))

        #expect(viewModel.orders.count == 1)
    }
}
