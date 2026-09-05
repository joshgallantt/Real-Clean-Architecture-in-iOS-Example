import Combine
import Product
import ProductTestSupport
import SnackbarUITestSupport
import SnapshotTesting
import SwiftUI
import Testing
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
            couldNotLoad: "We could not load your list."
        ),
        title: "Saved",
        emptyTitle: "Nothing saved yet",
        emptyIcon: "heart",
        emptyMessage: "Tap the heart on anything you want to come back to.",
        onSelect: { _ in },
        accessory: { _ in AnyView(EmptyView()) },
        leadingAccessory: { _ in AnyView(EmptyView()) }
    )

    assertSnapshot(of: list, as: .image(layout: .device(config: .iPhone13)))
}
