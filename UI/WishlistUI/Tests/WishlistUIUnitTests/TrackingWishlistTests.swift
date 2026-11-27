import AuthUITestSupport
import Combine
import Foundation
import ProductTestSupport
import SessionTestSupport
import SettingsTestSupport
import SnackbarUITestSupport
import Testing
import Product
import Tracking
import TrackingTestSupport
import TrackingUI
import Wishlist
import WishlistTestSupport
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
    private let navigation = SpyWishlistNavigation()

    private func faves(lookUp: SpyLookUpProductsUseCase) -> SavedProductsViewModel {
        let observeWishlist = StubObserveWishlistUseCase()
        observeWishlist.send(.holding([pid(1), pid(2)]))
        return SavedProductsViewModel(
            observeWishlist: observeWishlist,
            lookUpProducts: lookUp,
            setProductIsWishlisted: SpySetProductIsWishlistedUseCase(),
            navigation: navigation,
            snackbar: SpySnackbarPresenting(),
            trackScreenView: screens,
            trackElementView: views,
            trackElementInteraction: taps,
            pageSize: 30
        )
    }

    private func theTab(auth: SpyAuthPresenting) -> WishlistScreenViewModel {
        WishlistScreenViewModel(
            observeSession: SpyObserveSessionUseCase(),
            observeSetting: StubObserveSettingUseCase(turnedOff: []),
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
        faves(lookUp: SpyLookUpProductsUseCase()).didAppear(in: .screen("wishlist_faves"))

        #expect(screens.events == [TrackingEvent(name: .screenViewed, context: .screen("wishlist_faves"), items: [], properties: [:])])
    }

    @Test("A card seen in My Faves is an impression in that list, at its position")
    func cardSeen() {
        let product = Product.fixture(id: 2)
        let where_ = TrackingContext.list("wishlist", faves, index: 1)

        faves(lookUp: SpyLookUpProductsUseCase()).didSee(product, in: where_)

        #expect(views.events == [TrackingEvent(name: .elementViewed, context: where_, items: [TrackedProduct.item(product)], properties: ["element": "product"])])
    }

    @Test("A card tapped in My Faves is a tap in that list, and then opens the product")
    func cardTapped() {
        let product = Product.fixture(id: 9)
        let where_ = TrackingContext.list("wishlist", faves, index: 0)

        faves(lookUp: SpyLookUpProductsUseCase()).didSelect(product, in: where_)

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: where_, items: [TrackedProduct.item(product)], properties: ["element": "product"])])
        #expect(navigation.openedProducts.map(\.id) == [product.id])
    }

    @Test("View All says which list it opened")
    func viewAll() {
        theTab(auth: SpyAuthPresenting()).didTapViewAllFaves(in: tab)

        #expect(taps.events == [
            TrackingEvent(name: .elementSelected, context: tab, items: [.content(id: "wishlist_faves", name: "My Faves")], properties: ["element": "view_all"])
        ])
    }

    @Test("A list that will not load says so, and the snackbar saying it is seen where the list was")
    func snackbarSeen() async {
        let lookUp = SpyLookUpProductsUseCase()
        lookUp.result = .failure(.unavailable)
        let viewModel = faves(lookUp: lookUp)

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
