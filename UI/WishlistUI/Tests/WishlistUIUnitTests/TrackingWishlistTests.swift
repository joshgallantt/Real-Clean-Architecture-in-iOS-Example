import AuthUITestSupport
import Combine
import Foundation
import ProductTestSupport
import SessionTestSupport
import SnackbarUITestSupport
import Testing
import Product
import Tracking
import TrackingTestSupport
import TrackingUI
@testable import WishlistUI
@testable import WishlistUITestSupport

@MainActor
@Suite("What the wishlist tab tells the shop")
/// Where each event happened arrives as the context the view read — the tab, a full list's own
/// screen, or a card's position in a list — so these say what the wishlist reports, given where.
struct TrackingWishlistTests {
    private let screens = SpyTrackScreenViewUseCase()
    private let views = SpyTrackElementViewUseCase()
    private let taps = SpyTrackElementInteractionUseCase()

    private let tab = TrackingContext.screen("wishlist")
    private let faves = TrackingContext.List(id: "wishlist_faves", name: "My Faves")
    private let waitlistList = TrackingContext.List(id: "wishlist_waitlist", name: "Waitlist")

    private func faves(
        lookUp: SpyLookUpProductsUseCase,
        opened: @escaping @MainActor (Product) -> Void
    ) -> SavedProductsViewModel {
        SavedProductsViewModel(
            savedProductIds: StubObserveSavedProductIds([pid(1), pid(2)]).callAsFunction,
            lookUpProducts: lookUp,
            snackbar: SpySnackbarPresenting(),
            couldNotLoad: "Faves Won't Load",
            list: WishlistTrackingPlan.faves,
            openProduct: opened,
            trackScreenView: screens,
            trackElementView: views,
            trackElementInteraction: taps
        )
    }

    private func waitlist(load: SpyGetAlertedProducts, opened: @escaping @MainActor (Product) -> Void) -> AlertedProductsViewModel {
        AlertedProductsViewModel(
            load: load.callAsFunction,
            changes: StubObserveStockAlerts().callAsFunction,
            clear: SpyClearTheList().callAsFunction,
            snackbar: SpySnackbarPresenting(),
            couldNotLoad: "Waitlist Won't Load",
            list: WishlistTrackingPlan.waitlist,
            openProduct: opened,
            trackScreenView: screens,
            trackElementView: views,
            trackElementInteraction: taps
        )
    }

    private func theTab(auth: SpyAuthPresenting) -> WishlistScreenViewModel {
        WishlistScreenViewModel(
            observeSession: SpyObserveSessionUseCase(),
            authPresenter: auth,
            trackScreenView: screens,
            trackElementInteraction: taps
        )
    }

    @Test("The tab coming into view is one screen view, whatever lists are on it")
    func tabView() {
        theTab(auth: SpyAuthPresenting()).didAppear(in: tab)

        #expect(screens.events == [TrackingEvent(name: .screenViewed, context: .screen("wishlist"), items: [], properties: [:])])
    }

    @Test("A full list coming into view is its own screen")
    func fullListView() {
        faves(lookUp: SpyLookUpProductsUseCase(), opened: { _ in }).didAppear(in: .screen("wishlist_faves"))

        #expect(screens.events == [TrackingEvent(name: .screenViewed, context: .screen("wishlist_faves"), items: [], properties: [:])])
    }

    @Test("A card seen in My Faves is an impression in that list, at its position")
    func cardSeen() {
        let product = Product.fixture(id: 2)
        let where_ = TrackingContext.list("wishlist", faves, index: 1)

        faves(lookUp: SpyLookUpProductsUseCase(), opened: { _ in }).didSee(product, in: where_)

        #expect(views.events == [TrackingEvent(name: .elementViewed, context: where_, items: [TrackedProduct.item(product)], properties: ["element": "product"])])
    }

    @Test("A card tapped on the waitlist is a tap in the waitlist, and then opens the product")
    func cardTapped() {
        let product = Product.fixture(id: 9, availability: .outOfStock)
        let where_ = TrackingContext.list("wishlist", waitlistList, index: 0)
        var opened: [ProductID] = []

        waitlist(load: SpyGetAlertedProducts(), opened: { opened.append($0.id) }).didSelect(product, in: where_)

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: where_, items: [TrackedProduct.item(product)], properties: ["element": "product"])])
        #expect(opened == [product.id])
    }

    @Test("View All says which list it opened")
    func viewAll() {
        theTab(auth: SpyAuthPresenting()).didTapViewAll(WishlistTrackingPlan.backInStock, in: tab)

        #expect(taps.events == [
            TrackingEvent(name: .elementSelected, context: tab, items: [.content(id: "wishlist_back_in_stock", name: "Back in Stock")], properties: ["element": "view_all"])
        ])
    }

    @Test("Confirming Clear is a tap about the list being emptied")
    func clearConfirmed() async {
        let load = SpyGetAlertedProducts()
        load.result = .success([.fixture(id: 1, availability: .outOfStock)])
        let viewModel = waitlist(load: load, opened: { _ in })
        await viewModel.onAppear(in: tab)

        viewModel.didConfirmClear(in: tab)

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: tab, items: [.content(id: "wishlist_waitlist", name: "Waitlist")], properties: ["element": "clear"])])
    }

    @Test("Clearing a list that is already empty is not reported, because nothing was cleared")
    func clearingNothing() {
        waitlist(load: SpyGetAlertedProducts(), opened: { _ in }).didConfirmClear(in: tab)

        #expect(taps.events.isEmpty)
    }

    @Test("A list that will not load says so, and the snackbar saying it is seen where the list was")
    func snackbarSeen() async {
        let lookUp = SpyLookUpProductsUseCase()
        lookUp.result = .failure(.unavailable)
        let viewModel = faves(lookUp: lookUp, opened: { _ in })

        viewModel.onAppear(in: tab)
        await viewModel.inFlight?.value

        #expect(views.events == [TrackingEvent(name: .elementViewed, context: tab, items: [], properties: ["element": "faves_won_t_load"])])
    }

    @Test("Signing in from the guest prompt is a tap, and the tab is viewed again once the sheet closes")
    func signIn() async {
        let viewModel = theTab(auth: SpyAuthPresenting())

        viewModel.didTapSignIn(in: tab)
        await viewModel.inFlight?.value

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: tab, items: [], properties: ["element": "sign_in"])])
        #expect(screens.events == [TrackingEvent(name: .screenViewed, context: .screen("wishlist"), items: [], properties: [:])])
    }
}
