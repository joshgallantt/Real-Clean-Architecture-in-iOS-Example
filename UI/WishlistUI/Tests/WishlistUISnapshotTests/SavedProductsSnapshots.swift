import Combine
import Product
import ProductTestSupport
import SnackbarUITestSupport
import SnapshotTesting
import SwiftUI
import Testing
import Tracking
import TrackingTestSupport
@testable import WishlistUI
@testable import WishlistUITestSupport

@MainActor
@Test("A shopper who has saved nothing is told what saving is for")
func anEmptyWishlistExplainsItself() {
    let list = SavedProductsListView(
        viewModel: SavedProductsViewModel(
            savedProductIds: { Just([]).eraseToAnyPublisher() },
            lookUpProducts: SpyLookUpProductsUseCase(),
            snackbar: SpySnackbarPresenting(),
            couldNotLoad: "We could not load your list.",
            list: WishlistTrackingPlan.faves,
            openProduct: { _ in },
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementView: SpyTrackElementViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase()
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
