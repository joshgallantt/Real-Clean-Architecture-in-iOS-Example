import HomeTestSupport
import Product
import SnapshotTesting
import SwiftUI
import Testing
import Tracking
import TrackingTestSupport
@testable import HomeUI
@testable import HomeUITestSupport

@MainActor
@Test("The home screen renders its frame before the feed has arrived")
func theHomeScreenRendersBeforeTheFeedArrives() {
    let screen = HomeScreenView(
        viewModel: HomeScreenViewModel(
            drawHomeFeed: SpyDrawHomeFeedUseCase(),
            navigation: SpyHomeNavigation(),
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementView: SpyTrackElementViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase()
        ),
        wishlistButton: { _ in AnyView(EmptyView()) },
        bagButton: { _ in AnyView(EmptyView()) }
    )

    assertSnapshot(of: screen, as: .image(layout: .device(config: .iPhone13)))
}
