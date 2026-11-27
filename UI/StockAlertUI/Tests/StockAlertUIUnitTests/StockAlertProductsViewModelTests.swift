import Foundation
import ProductTestSupport
import SnackbarUITestSupport
import Testing
import Tracking
import TrackingTestSupport
import Product
import StockAlert
import StockAlertTestSupport
@testable import StockAlertUI
@testable import StockAlertUITestSupport

@MainActor
@Suite("A list built from what the shop says about a shopper's stock alerts")
struct StockAlertProductsViewModelTests {
    private let getStockAlertProducts = SpyGetStockAlertProductsUseCase()
    private let observeStockAlerts = StubObserveStockAlertsUseCase()
    private let setProductStockAlert = SpySetProductStockAlertUseCase()
    private let snackbar = SpySnackbarPresenting()
    private let tab = TrackingContext.screen("wishlist")

    private func makeViewModel() -> StockAlertProductsViewModel {
        StockAlertProductsViewModel(
            getStockAlertProducts: getStockAlertProducts,
            observeStockAlerts: observeStockAlerts,
            setProductStockAlert: setProductStockAlert,
            navigation: SpyStockAlertNavigation(),
            snackbar: snackbar,
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementView: SpyTrackElementViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase()
        )
    }

    @Test("Appearing shows whatever the load returns, in the order it returns it")
    func appearingShowsWhatLoadReturns() async {
        getStockAlertProducts.result = .success([.fixture(id: 2), .fixture(id: 1, availability: .outOfStock)])
        let viewModel = makeViewModel()

        await viewModel.onAppear(in: tab)

        #expect(viewModel.products.map(\.id) == [pid(2), pid(1)])
        #expect(viewModel.count == 2)
        #expect(viewModel.isEmpty == false)
    }

    @Test("A change in what was asked reloads the list")
    func aChangeReloadsTheList() async {
        getStockAlertProducts.result = .success([])
        let viewModel = makeViewModel()
        await viewModel.onAppear(in: tab)
        let loadsSoFar = getStockAlertProducts.callCount

        observeStockAlerts.send(StockAlerts(items: [StockAlert(productId: pid(1))]))
        await viewModel.inFlight?.value

        #expect(getStockAlertProducts.callCount > loadsSoFar)
    }

    @Test("The same alerts reported twice reload only once")
    func theSameAlertsTwiceReloadOnce() async {
        let viewModel = makeViewModel()
        await viewModel.onAppear(in: tab)
        let same = StockAlerts(items: [StockAlert(productId: pid(1))])
        observeStockAlerts.send(same)
        await viewModel.inFlight?.value
        let loadsSoFar = getStockAlertProducts.callCount

        observeStockAlerts.send(same)
        await viewModel.inFlight?.value

        #expect(getStockAlertProducts.callCount == loadsSoFar)
    }

    @Test("A dropped connection leaves the list exactly as it was, rather than emptying it")
    func aDroppedConnectionLeavesTheListAsItWas() async {
        getStockAlertProducts.result = .success([.fixture(id: 1)])
        let viewModel = makeViewModel()
        await viewModel.onAppear(in: tab)

        getStockAlertProducts.result = .failure(.unavailable)
        await viewModel.onAppear(in: tab)

        #expect(viewModel.products.map(\.id) == [pid(1)])
    }

    @Test("A dropped connection is reported as the stock alerts not loading")
    func aDroppedConnectionIsReportedWithItsOwnTitle() async {
        getStockAlertProducts.result = .failure(.unavailable)
        let viewModel = makeViewModel()

        await viewModel.onAppear(in: tab)

        #expect(snackbar.shown.first?.title == "Stock Alerts Won't Load")
    }

    @Test("Clearing turns off every alert currently on the list, back or not")
    func clearingTakesEverythingOnTheList() async {
        getStockAlertProducts.result = .success([.fixture(id: 2), .fixture(id: 1, availability: .outOfStock)])
        let viewModel = makeViewModel()
        await viewModel.onAppear(in: tab)

        viewModel.didConfirmClear(in: tab)
        await viewModel.inFlight?.value

        #expect(setProductStockAlert.calls.map(\.productId) == [pid(2), pid(1)])
        #expect(setProductStockAlert.calls.allSatisfy { $0.isOn == false })
    }

    @Test("Clearing an empty list asks nothing of anybody")
    func clearingAnEmptyListAsksNothing() async {
        let viewModel = makeViewModel()
        await viewModel.onAppear(in: tab)

        viewModel.didConfirmClear(in: tab)
        await viewModel.inFlight?.value

        #expect(setProductStockAlert.calls.isEmpty)
    }
}
