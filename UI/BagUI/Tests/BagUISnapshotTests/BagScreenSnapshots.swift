import Bag
import BagTestSupport
import Product
import SnapshotTesting
import SwiftUI
import Testing
@testable import BagUI
@testable import BagUITestSupport

@MainActor
@Test("An empty bag says so rather than showing a blank screen")
func anEmptyBagSaysSo() {
    let screen = BagScreenView(
        viewModel: BagScreenViewModel(
            navigation: SpyBagNavigation(),
            observeBag: StubObserveBagUseCase(),
            observeNotices: StubObserveNoticesUseCase(),
            setBagItemQuantity: SpySetBagItemQuantityUseCase(),
            bringBagUpToDate: SpyBringBagUpToDateUseCase(),
            acknowledgeNotices: SpyAcknowledgeNoticesUseCase()
        ),
        stockAlertButton: { _ in AnyView(EmptyView()) },
        checkoutButton: AnyView(EmptyView())
    )

    assertSnapshot(of: screen, as: .image(layout: .device(config: .iPhone13)))
}
