import AuthUITestSupport
import BagTestSupport
import Foundation
import ProductTestSupport
import SnackbarUITestSupport
import Testing
import Product
import Bag
import Tracking
import TrackingTestSupport
import TrackingUI
import StockAlertTestSupport
import WishlistTestSupport
@testable import ProductActionsUI
@testable import ProductActionsUITestSupport

@MainActor
@Suite("What the product buttons tell the shop")
/// Each button reports wherever its view says it is drawn — the third card in a carousel, or a
/// product page — and never knows which screen that is.
struct TrackingProductActionsTests {
    private let screens = SpyTrackScreenViewUseCase()
    private let views = SpyTrackElementViewUseCase()
    private let taps = SpyTrackElementInteractionUseCase()
    private let reported = SpyTrackEventUseCase()
    private let bag = SpySetBagItemUseCase()

    private let onTheThirdCard = TrackingContext.list("home", TrackingContext.List(id: "home_carousel_beauty", name: "Beauty"), index: 2)
    private let onAPage = TrackingContext.screen("product_details")

    private func heart(
        _ product: Product,
        isSaved: Bool,
        set: SpySetProductIsWishlistedUseCase,
        auth: SpyAuthPresenting
    ) -> WishlistButtonViewModel {
        let viewModel = WishlistButtonViewModel(
            product: product,
            observeProductIsWishlisted: StubObserveProductIsWishlistedUseCase(isSaved),
            setProductIsWishlisted: set,
            authPresenter: auth,
            snackbarPresenter: SpySnackbarPresenting(),
            trackScreenView: screens,
            trackElementView: views,
            trackElementInteraction: taps,
            trackEvent: reported
        )
        viewModel.onAppear()
        return viewModel
    }

    private func bagButton(_ product: Product, snackbars: SpySnackbarPresenting) -> BagButtonViewModel {
        BagButtonViewModel(
            product: product,
            observeBag: StubObserveBagUseCase(Bag(items: [])),
            setBagItem: bag,
            navigation: SpyProductActionsNavigation(),
            snackbarPresenter: snackbars,
            trackElementView: views,
            trackElementInteraction: taps,
            trackEvent: reported
        )
    }

    // MARK: - The heart

    @Test("Hearting the third card in a carousel is a tap at that position, then the product saved")
    func heartInACarousel() async {
        let product = Product.fixture(id: 3)
        let viewModel = heart(product, isSaved: false, set: SpySetProductIsWishlistedUseCase(), auth: SpyAuthPresenting())

        viewModel.didTap(in: onTheThirdCard)
        await viewModel.inFlight?.value

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: onTheThirdCard, items: [TrackedProduct.item(product)], properties: ["element": "wishlist_on"])])
        #expect(reported.events == [
            TrackingEvent(name: .productAddedToWishlist, context: onTheThirdCard, items: [TrackedProduct.item(product)], properties: [:])
        ])
    }

    @Test("The same heart on a product page is a tap on that page")
    func heartOnAPage() async {
        let viewModel = heart(.fixture(id: 3), isSaved: false, set: SpySetProductIsWishlistedUseCase(), auth: SpyAuthPresenting())

        viewModel.didTap(in: onAPage)
        await viewModel.inFlight?.value

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: onAPage, items: [TrackedProduct.item(.fixture(id: 3))], properties: ["element": "wishlist_on"])])
    }

    @Test("Un-hearting is the heart turned off, and saves nothing")
    func heartOff() async {
        let viewModel = heart(.fixture(id: 3), isSaved: true, set: SpySetProductIsWishlistedUseCase(), auth: SpyAuthPresenting())

        viewModel.didTap(in: onAPage)
        await viewModel.inFlight?.value

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: onAPage, items: [TrackedProduct.item(.fixture(id: 3))], properties: ["element": "wishlist_off"])])
        #expect(reported.events.isEmpty)
    }

    @Test("A save that did not stick is a tap, not a product saved")
    func failedSave() async {
        let set = SpySetProductIsWishlistedUseCase()
        set.result = .failure(.unavailable)
        let viewModel = heart(.fixture(id: 3), isSaved: false, set: set, auth: SpyAuthPresenting())

        viewModel.didTap(in: onAPage)
        await viewModel.inFlight?.value

        #expect(reported.events.isEmpty)
    }

    @Test("Signing in part-way through is one tap and one save, and the screen behind the sheet is viewed again")
    func signingIn() async {
        let set = SpySetProductIsWishlistedUseCase()
        set.result = .failure(.unauthenticated)
        let auth = SpyAuthPresenting(onSignIn: { set.result = .success(()) })
        auth.signsIn = true
        let product = Product.fixture(id: 3)
        let viewModel = heart(product, isSaved: false, set: set, auth: auth)

        viewModel.didTap(in: onTheThirdCard)
        await viewModel.inFlight?.value

        #expect(taps.events.count == 1)
        #expect(reported.events == [
            TrackingEvent(name: .productAddedToWishlist, context: onTheThirdCard, items: [TrackedProduct.item(product)], properties: [:])
        ])
        #expect(screens.events == [TrackingEvent(name: .screenViewed, context: .screen("home"), items: [], properties: [:])])
    }

    @Test("The snackbar the heart shows is seen where the heart was")
    func snackbarSeen() async {
        let viewModel = heart(.fixture(id: 3), isSaved: false, set: SpySetProductIsWishlistedUseCase(), auth: SpyAuthPresenting())

        viewModel.didTap(in: onAPage)
        await viewModel.inFlight?.value

        #expect(views.events == [TrackingEvent(name: .elementViewed, context: onAPage, items: [TrackedProduct.item(.fixture(id: 3))], properties: ["element": "saved"])])
    }

    // MARK: - The bag button

    @Test("Adding to the bag is a tap, one of the product added at the price the bag was handed, and the snackbar seen")
    func addToBag() {
        let product = Product.fixture(id: 8, price: 4.25)

        bagButton(product, snackbars: SpySnackbarPresenting()).didTap(in: onTheThirdCard)

        let item = TrackedProduct.item(product)
        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: onTheThirdCard, items: [item], properties: ["element": "add_to_bag"])])
        #expect(views.events == [TrackingEvent(name: .elementViewed, context: onTheThirdCard, items: [item], properties: ["element": "in_the_bag"])])
        #expect(reported.events == [
            TrackingEvent(
                name: .productAdded,
                context: onTheThirdCard,
                items: [TrackedProduct.item(product, price: product.price, quantity: 1)],
                properties: [:]
            )
        ])
        #expect(bag.calls.map(\.quantity) == [1])
        #expect(bag.calls.map(\.lastKnownPrice) == [product.price])
    }

    @Test("Following the snackbar to the bag is its own tap, where the button was")
    func snackbarViewBag() {
        let snackbars = SpySnackbarPresenting()

        bagButton(.fixture(id: 8), snackbars: snackbars).didTap(in: onAPage)
        snackbars.shown.first?.action?.handler()

        #expect(taps.events.last == TrackingEvent(name: .elementSelected, context: onAPage, items: [], properties: ["element": "snackbar_view_bag"]))
    }

    @Test("A bag button that refuses a sold-out product reports nothing, because nothing happened")
    func soldOut() {
        bagButton(.fixture(id: 8, availability: .outOfStock), snackbars: SpySnackbarPresenting()).didTap(in: onAPage)

        #expect(taps.events.isEmpty)
        #expect(reported.events.isEmpty)
    }

    // MARK: - The bell

    @Test("Ringing the bell is the bell turned on; the minus is a removal")
    func bellAndMinus() async {
        let product = Product.fixture(id: 5, availability: .outOfStock)
        let viewModel = StockAlertButtonViewModel(
            product: product,
            observeProductHasStockAlert: StubObserveProductHasStockAlertUseCase(false),
            setProductStockAlert: SpySetProductStockAlertUseCase(),
            authPresenter: SpyAuthPresenting(),
            snackbarPresenter: SpySnackbarPresenting(),
            trackScreenView: screens,
            trackElementView: views,
            trackElementInteraction: taps
        )
        viewModel.onAppear()

        viewModel.didTap(in: onAPage)
        viewModel.didTapRemove(in: onAPage)
        await viewModel.inFlight?.value

        #expect(taps.events == [
            TrackingEvent(name: .elementSelected, context: onAPage, items: [TrackedProduct.item(product)], properties: ["element": "stock_alert_on"]),
            TrackingEvent(name: .elementSelected, context: onAPage, items: [TrackedProduct.item(product)], properties: ["element": "remove_stock_alert"])
        ])
    }

    @Test("Tapping a bell that is already ringing is the bell turned off")
    func bellOff() async {
        let product = Product.fixture(id: 5, availability: .outOfStock)
        let viewModel = StockAlertButtonViewModel(
            product: product,
            observeProductHasStockAlert: StubObserveProductHasStockAlertUseCase(true),
            setProductStockAlert: SpySetProductStockAlertUseCase(),
            authPresenter: SpyAuthPresenting(),
            snackbarPresenter: SpySnackbarPresenting(),
            trackScreenView: screens,
            trackElementView: views,
            trackElementInteraction: taps
        )
        viewModel.onAppear()

        viewModel.didTap(in: onAPage)
        await viewModel.inFlight?.value

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: onAPage, items: [TrackedProduct.item(product)], properties: ["element": "stock_alert_off"])])
    }
}
