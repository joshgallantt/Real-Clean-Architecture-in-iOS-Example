import Foundation
import ProductTestSupport
import SnackbarUITestSupport
import Testing
import Product
import Tracking
import TrackingTestSupport
import TrackingUI
import StockAlertTestSupport
@testable import StockAlertUI
@testable import StockAlertUITestSupport

@MainActor
@Suite("What the stock alerts list tells the shop")
/// Where each event happened arrives as the context the view read — the tab the row is drawn on,
/// the list's own screen, or a card's position in the list — so these say what the list reports,
/// given where.
struct TrackingStockAlertsTests {
    private let screens = SpyTrackScreenViewUseCase()
    private let views = SpyTrackElementViewUseCase()
    private let taps = SpyTrackElementInteractionUseCase()
    private let getStockAlertProducts = SpyGetStockAlertProductsUseCase()
    private let navigation = SpyStockAlertNavigation()

    private let tab = TrackingContext.screen("wishlist")
    private let stockAlerts = TrackingContext.List(id: "wishlist_stock_alerts", name: "Stock Alerts")

    private func makeViewModel() -> StockAlertProductsViewModel {
        StockAlertProductsViewModel(
            getStockAlertProducts: getStockAlertProducts,
            observeStockAlerts: StubObserveStockAlertsUseCase(),
            setProductStockAlert: SpySetProductStockAlertUseCase(),
            navigation: navigation,
            snackbar: SpySnackbarPresenting(),
            trackScreenView: screens,
            trackElementView: views,
            trackElementInteraction: taps
        )
    }

    @Test("The full list coming into view is its own screen")
    func fullListView() {
        makeViewModel().didAppear(in: .screen(StockAlertTrackingPlan.screen))

        #expect(screens.events == [TrackingEvent(name: .screenViewed, context: .screen("wishlist_stock_alerts"), items: [], properties: [:])])
    }

    @Test("A card seen in the list is an impression in that list, at its position")
    func cardSeen() {
        let product = Product.fixture(id: 2)
        let where_ = TrackingContext.list("wishlist", stockAlerts, index: 1)

        makeViewModel().didSee(product, in: where_)

        #expect(views.events == [TrackingEvent(name: .elementViewed, context: where_, items: [TrackedProduct.item(product)], properties: ["element": "product"])])
    }

    @Test("A card tapped in the list is a tap in that list, and then opens the product")
    func cardTapped() {
        let product = Product.fixture(id: 9, availability: .outOfStock)
        let where_ = TrackingContext.list("wishlist", stockAlerts, index: 0)

        makeViewModel().didSelect(product, in: where_)

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: where_, items: [TrackedProduct.item(product)], properties: ["element": "product"])])
        #expect(navigation.openedProducts.map(\.id) == [product.id])
    }

    @Test("View All says which list it opened, and opens it")
    func viewAll() {
        makeViewModel().didTapViewAll(in: tab)

        #expect(taps.events == [
            TrackingEvent(name: .elementSelected, context: tab, items: [.content(id: "wishlist_stock_alerts", name: "Stock Alerts")], properties: ["element": "view_all"])
        ])
        #expect(navigation.openedAllStockAlerts == 1)
    }

    @Test("Confirming Clear is a tap about the list being emptied")
    func clearConfirmed() async {
        getStockAlertProducts.result = .success([.fixture(id: 1, availability: .outOfStock)])
        let viewModel = makeViewModel()
        await viewModel.onAppear(in: tab)

        viewModel.didConfirmClear(in: tab)

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: tab, items: [.content(id: "wishlist_stock_alerts", name: "Stock Alerts")], properties: ["element": "clear"])])
    }

    @Test("Clearing a list that is already empty is not reported, because nothing was cleared")
    func clearingNothing() {
        makeViewModel().didConfirmClear(in: tab)

        #expect(taps.events.isEmpty)
    }

    @Test("A list that will not load says so, and the snackbar saying it is seen where the list was")
    func snackbarSeen() async {
        getStockAlertProducts.result = .failure(.unavailable)

        await makeViewModel().onAppear(in: tab)

        #expect(views.events == [TrackingEvent(name: .elementViewed, context: tab, items: [], properties: ["element": "stock_alerts_won_t_load"])])
    }
}
