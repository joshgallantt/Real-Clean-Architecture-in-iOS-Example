import Foundation
import ProductTestSupport
import SnackbarUITestSupport
import Testing
import Tracking
import TrackingTestSupport
import Product
import Wishlist
import WishlistTestSupport
@testable import WishlistUI
@testable import WishlistUITestSupport

@MainActor
@Suite("A list of saved ids, filled in from the catalog")
struct SavedProductsViewModelTests {
    private let observeWishlist = StubObserveWishlistUseCase()
    private let lookUpProducts = SpyLookUpProductsUseCase()
    private let setProductIsWishlisted = SpySetProductIsWishlistedUseCase()
    private let snackbar = SpySnackbarPresenting()

    private func makeViewModel(pageSize: Int) -> SavedProductsViewModel {
        SavedProductsViewModel(
            observeWishlist: observeWishlist,
            lookUpProducts: lookUpProducts,
            setProductIsWishlisted: setProductIsWishlisted,
            navigation: SpyWishlistNavigation(),
            snackbar: snackbar,
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementView: SpyTrackElementViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase(),
            pageSize: pageSize
        )
    }

    @Test("What a shopper is holding is filled in from the catalog")
    func showsWhatIsHeldFilledIn() async {
        observeWishlist.send(.holding([pid(1), pid(2)]))
        lookUpProducts.result = .success([.fixture(id: 1), .fixture(id: 2)])
        let viewModel = makeViewModel(pageSize: 30)

        viewModel.onAppear(in: TrackingContext.screen(WishlistTrackingPlan.screen))
        await viewModel.inFlight?.value

        #expect(viewModel.products.map(\.id) == [pid(1), pid(2)])
        #expect(viewModel.savedCount == 2)
    }

    @Test("Holding nothing asks the shop nothing")
    func holdingNothingAsksNothing() async {
        let viewModel = makeViewModel(pageSize: 30)

        viewModel.onAppear(in: TrackingContext.screen(WishlistTrackingPlan.screen))
        await viewModel.inFlight?.value

        #expect(viewModel.isEmpty)
        #expect(lookUpProducts.asked.isEmpty)
    }

    @Test("Something the shop no longer answers about is not shown")
    func discontinuedIsNotShown() async {
        observeWishlist.send(.holding([pid(1), pid(2)]))
        lookUpProducts.result = .success([.fixture(id: 1)])
        let viewModel = makeViewModel(pageSize: 30)

        viewModel.onAppear(in: TrackingContext.screen(WishlistTrackingPlan.screen))
        await viewModel.inFlight?.value

        #expect(viewModel.products.map(\.id) == [pid(1)])
    }

    @Test("The count is what the shopper holds, not what fits on screen")
    func countIsOfEverythingHeldNotJustShown() async {
        observeWishlist.send(.holding((1...5).map(pid)))
        lookUpProducts.result = .success((1...2).map { .fixture(id: $0) })
        let viewModel = makeViewModel(pageSize: 2)

        viewModel.onAppear(in: TrackingContext.screen(WishlistTrackingPlan.screen))
        await viewModel.inFlight?.value

        #expect(viewModel.products.count == 2)
        #expect(viewModel.savedCount == 5)
    }

    @Test("Reaching the end of the list asks for the next page")
    func reachingTheEndAsksForTheNextPage() async {
        observeWishlist.send(.holding((1...5).map(pid)))
        lookUpProducts.result = .success((1...5).map { .fixture(id: $0) })
        let viewModel = makeViewModel(pageSize: 2)
        viewModel.onAppear(in: TrackingContext.screen(WishlistTrackingPlan.screen))
        await viewModel.inFlight?.value

        viewModel.didLayOut(viewModel.products[viewModel.products.count - 1], in: TrackingContext.screen(WishlistTrackingPlan.screen))
        await viewModel.inFlight?.value

        #expect(viewModel.products.count == 4)
    }

    @Test("A dropped connection leaves the list exactly as it was")
    func aDroppedConnectionLeavesTheListAsItWas() async {
        observeWishlist.send(.holding([pid(1)]))
        lookUpProducts.result = .success([.fixture(id: 1)])
        let viewModel = makeViewModel(pageSize: 30)
        viewModel.onAppear(in: TrackingContext.screen(WishlistTrackingPlan.screen))
        await viewModel.inFlight?.value

        observeWishlist.send(.holding([pid(1), pid(2)]))
        lookUpProducts.result = .failure(.unavailable)
        await viewModel.inFlight?.value

        #expect(viewModel.products.map(\.id) == [pid(1)])
        #expect(viewModel.isEmpty == false)
    }

    @Test("A dropped connection is reported as the faves not loading")
    func aDroppedConnectionIsReportedWithItsOwnTitle() async {
        observeWishlist.send(.holding([pid(1)]))
        lookUpProducts.result = .failure(.unavailable)
        let viewModel = makeViewModel(pageSize: 30)

        viewModel.onAppear(in: TrackingContext.screen(WishlistTrackingPlan.screen))
        await viewModel.inFlight?.value

        #expect(snackbar.shown.first?.title == "Faves Won't Load")
    }

    @Test("Clearing takes away everything currently on the list")
    func clearingTakesEverythingOnTheList() async {
        observeWishlist.send(.holding([pid(1), pid(2)]))
        lookUpProducts.result = .success([.fixture(id: 1), .fixture(id: 2)])
        let viewModel = makeViewModel(pageSize: 30)
        viewModel.onAppear(in: TrackingContext.screen(WishlistTrackingPlan.screen))
        await viewModel.inFlight?.value

        viewModel.didConfirmClear(in: TrackingContext.screen(WishlistTrackingPlan.screen))
        await viewModel.inFlight?.value

        #expect(setProductIsWishlisted.calls.map(\.productId) == [pid(1), pid(2)])
        #expect(setProductIsWishlisted.calls.allSatisfy { $0.isWishlisted == false })
    }

    @Test("Clearing an empty list asks nothing of anybody")
    func clearingAnEmptyListAsksNothing() async {
        let viewModel = makeViewModel(pageSize: 30)
        viewModel.onAppear(in: TrackingContext.screen(WishlistTrackingPlan.screen))
        await viewModel.inFlight?.value

        viewModel.didConfirmClear(in: TrackingContext.screen(WishlistTrackingPlan.screen))
        await viewModel.inFlight?.value

        #expect(setProductIsWishlisted.calls.isEmpty)
    }

    @Test("Something already filled in is not asked about again")
    func doesNotReaskForWhatItHas() async {
        observeWishlist.send(.holding([pid(1)]))
        lookUpProducts.result = .success([.fixture(id: 1)])
        let viewModel = makeViewModel(pageSize: 30)
        viewModel.onAppear(in: TrackingContext.screen(WishlistTrackingPlan.screen))
        await viewModel.inFlight?.value

        observeWishlist.send(.holding([pid(1), pid(2)]))
        lookUpProducts.result = .success([.fixture(id: 2)])
        await viewModel.inFlight?.value

        #expect(lookUpProducts.asked == [[pid(1)], [pid(2)]])
    }

    @Test("Appearing again does not subscribe a second time")
    func appearingAgainDoesNotResubscribe() async {
        observeWishlist.send(.holding([pid(1)]))
        lookUpProducts.result = .success([.fixture(id: 1)])
        let viewModel = makeViewModel(pageSize: 30)
        viewModel.onAppear(in: TrackingContext.screen(WishlistTrackingPlan.screen))
        await viewModel.inFlight?.value

        viewModel.onAppear(in: TrackingContext.screen(WishlistTrackingPlan.screen))
        lookUpProducts.result = .success([.fixture(id: 2)])
        observeWishlist.send(.holding([pid(1), pid(2)]))
        await viewModel.inFlight?.value

        #expect(lookUpProducts.asked == [[pid(1)], [pid(2)]])
    }
}
