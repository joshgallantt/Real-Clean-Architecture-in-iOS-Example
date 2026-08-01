import Foundation
import Testing
import Product
import StockAlert
@testable import WishlistUI

@MainActor
@Suite("A list built from what the shop says about a set of asks")
struct AlertedProductsViewModelTests {
    private func makeViewModel(
        load: StubGetAlertedProducts = StubGetAlertedProducts(),
        changes: StubObserveStockAlerts = StubObserveStockAlerts(),
        clear: SpyClearTheList = SpyClearTheList(),
        snackbar: SpySnackbarPresenter = SpySnackbarPresenter(),
        couldNotLoad: String = "Couldn't Load"
    ) -> AlertedProductsViewModel {
        AlertedProductsViewModel(
            load: load.callAsFunction,
            changes: changes.callAsFunction,
            clear: clear.callAsFunction,
            snackbar: snackbar,
            couldNotLoad: couldNotLoad
        )
    }

    @Test("Appearing shows whatever the load returns")
    func appearingShowsWhatLoadReturns() async {
        let load = StubGetAlertedProducts()
        load.result = .success([.fixture(id: 1), .fixture(id: 2)])
        let viewModel = makeViewModel(load: load)

        viewModel.onAppear()
        await settle()

        #expect(viewModel.products.map(\.id) == [pid(1), pid(2)])
        #expect(viewModel.count == 2)
        #expect(viewModel.isEmpty == false)
    }

    @Test("A change on what is asked reloads the list")
    func aChangeReloadsTheList() async {
        let load = StubGetAlertedProducts()
        load.result = .success([])
        let changes = StubObserveStockAlerts()
        let viewModel = makeViewModel(load: load, changes: changes)
        viewModel.onAppear()
        await settle()
        let loadsSoFar = load.callCount

        changes.send(StockAlerts(alerts: [StockAlert(productId: pid(1))]))
        await settle()

        #expect(load.callCount > loadsSoFar)
    }

    @Test("The same ask reported twice reloads only once")
    func theSameAskTwiceReloadsOnce() async {
        let load = StubGetAlertedProducts()
        let changes = StubObserveStockAlerts()
        let viewModel = makeViewModel(load: load, changes: changes)
        viewModel.onAppear()
        await settle()
        let same = StockAlerts(alerts: [StockAlert(productId: pid(1))])
        changes.send(same)
        await settle()
        let loadsSoFar = load.callCount

        changes.send(same)
        await settle()

        #expect(load.callCount == loadsSoFar)
    }

    @Test("A dropped connection leaves the list exactly as it was, rather than emptying it")
    func aDroppedConnectionLeavesTheListAsItWas() async {
        let load = StubGetAlertedProducts()
        load.result = .success([.fixture(id: 1)])
        let viewModel = makeViewModel(load: load)
        viewModel.onAppear()
        await settle()

        load.result = .failure(.unavailable)
        viewModel.onAppear()
        await settle()

        #expect(viewModel.products.map(\.id) == [pid(1)])
    }

    @Test("A dropped connection is reported with the title this list was given")
    func aDroppedConnectionIsReportedWithItsOwnTitle() async {
        let load = StubGetAlertedProducts()
        load.result = .failure(.unavailable)
        let snackbar = SpySnackbarPresenter()
        let viewModel = makeViewModel(load: load, snackbar: snackbar, couldNotLoad: "Couldn't Load the Waitlist")

        viewModel.onAppear()
        await settle()

        #expect(snackbar.shown.first?.title == "Couldn't Load the Waitlist")
    }

    @Test("Clearing takes away everything currently on the list")
    func clearingTakesEverythingOnTheList() async {
        let load = StubGetAlertedProducts()
        load.result = .success([.fixture(id: 1), .fixture(id: 2)])
        let clear = SpyClearTheList()
        let viewModel = makeViewModel(load: load, clear: clear)
        viewModel.onAppear()
        await settle()

        viewModel.didConfirmClear()
        await settle()

        #expect(clear.calls == [[pid(1), pid(2)]])
    }

    @Test("Clearing an empty list asks nothing of anybody")
    func clearingAnEmptyListAsksNothing() async {
        let clear = SpyClearTheList()
        let viewModel = makeViewModel(clear: clear)
        viewModel.onAppear()
        await settle()

        viewModel.didConfirmClear()
        await settle()

        #expect(clear.calls.isEmpty)
    }
}
