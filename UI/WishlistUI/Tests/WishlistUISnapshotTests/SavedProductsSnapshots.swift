import Product
import ProductTestSupport
import SnackbarUITestSupport
import SnapshotTesting
import SwiftUI
import Testing
import Tracking
import TrackingTestSupport
import WishlistTestSupport
@testable import WishlistUI
@testable import WishlistUITestSupport

@MainActor
@Test("A shopper who has saved nothing is told what saving is for")
func anEmptyWishlistExplainsItself() {
    let list = SavedProductsListView(
        viewModel: SavedProductsViewModel(
            observeWishlist: StubObserveWishlistUseCase(),
            lookUpProducts: SpyLookUpProductsUseCase(),
            setProductIsWishlisted: SpySetProductIsWishlistedUseCase(),
            navigation: SpyWishlistNavigation(),
            snackbar: SpySnackbarPresenting(),
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementView: SpyTrackElementViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase(),
            pageSize: 30
        ),
        title: "Saved",
        emptyTitle: "Nothing saved yet",
        emptyIcon: "heart",
        emptyMessage: "Tap the heart on anything you want to come back to.",
        listContext: WishlistTrackingPlan.faves,
        accessory: { _ in AnyView(EmptyView()) },
        leadingAccessory: { _ in AnyView(EmptyView()) }
    )

    assertSnapshot(of: list, as: .image(layout: .device(config: .iPhone13)))
}
