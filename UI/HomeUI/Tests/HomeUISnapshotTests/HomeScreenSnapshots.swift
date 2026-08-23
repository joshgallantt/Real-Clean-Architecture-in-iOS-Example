import Product
import SnapshotTesting
import SwiftUI
import Testing
@testable import HomeUI
@testable import HomeUITestSupport

@MainActor
@Test("The home screen renders its frame before the feed has arrived")
func theHomeScreenRendersBeforeTheFeedArrives() {
    let screen = HomeScreenView(
        viewModel: HomeScreenViewModel(drawHomeFeed: StubDrawHomeFeed(), navigation: StubNavigation()),
        wishlistButton: { _ in AnyView(EmptyView()) },
        bagButton: { _ in AnyView(EmptyView()) }
    )

    assertSnapshot(of: screen, as: .image(layout: .device(config: .iPhone13)))
}
