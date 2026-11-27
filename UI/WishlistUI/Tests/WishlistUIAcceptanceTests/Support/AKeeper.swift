import ProductTestSupport
import SnackbarUITestSupport
import Foundation
import Tracking
import TrackingTestSupport
import Product
import Wishlist
import WishlistTestSupport
@testable import WishlistUI
@testable import WishlistUITestSupport

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. Tests say what
/// a shopper has kept and what the shop said about it, never which type held it.
final class AKeeper {
    private let wishlist = StubObserveWishlistUseCase()
    private var kept: [ProductID] = []
    let shop = FakeLookUpProductsUseCase()
    let snackbars = SpySnackbarPresenting()

    private(set) lazy var list = SavedProductsViewModel(
        observeWishlist: wishlist,
        lookUpProducts: shop,
        setProductIsWishlisted: SpySetProductIsWishlistedUseCase(),
        navigation: SpyWishlistNavigation(),
        snackbar: snackbars,
        trackScreenView: SpyTrackScreenViewUseCase(),
        trackElementView: SpyTrackElementViewUseCase(),
        trackElementInteraction: SpyTrackElementInteractionUseCase(),
        pageSize: pageSize
    )

    var pageSize = 30

    /// What the shopper has saved. The list is told through the wishlist it observes.
    func keeps(_ ids: Int...) {
        keep(ids.map(pid))
    }

    func keeps(idsUpTo count: Int) {
        keep((1...count).map(pid))
    }

    func stopsKeeping(_ ids: Int...) {
        let dropped = Set(ids.map(pid))
        keep(kept.filter { !dropped.contains($0) })
    }

    private func keep(_ ids: [ProductID]) {
        kept = ids
        wishlist.send(.holding(ids))
    }

    /// Waits for the work the last interaction started, and nothing else.
    ///
    /// It used to yield two hundred times and hope. That is a guess about how
    /// busy the machine is rather than a wait, and it is why a suite fails once
    /// on the run after a rebuild and then passes for a month.
    func settle() async {
        await list.inFlight?.value
    }
}
