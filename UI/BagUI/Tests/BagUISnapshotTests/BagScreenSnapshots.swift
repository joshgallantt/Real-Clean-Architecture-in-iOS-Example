import Bag
import BagTestSupport
import Foundation
import Product
import ProductTestSupport
import SettingsTestSupport
import SnapshotTesting
import SwiftUI
import Testing
import Tracking
import TrackingTestSupport
@testable import BagUI
@testable import BagUITestSupport

@MainActor
private func bagScreen(kept: Bag, shopSays products: [Product]) -> (BagScreenView, BagScreenViewModel) {
    let viewModel = BagScreenViewModel(
        navigation: SpyBagNavigation(),
        observeBag: StubObserveBagUseCase(kept),
        setBagItem: SpySetBagItemUseCase(),
        checkBag: SpyCheckBagUseCase(answer: kept.checked(against: products, asked: Set(products.map(\.id)))),
        observeSetting: StubObserveSettingUseCase(turnedOff: []),
        trackScreenView: SpyTrackScreenViewUseCase(),
        trackElementView: SpyTrackElementViewUseCase(),
        trackElementInteraction: SpyTrackElementInteractionUseCase(),
        trackEvent: SpyTrackEventUseCase()
    )
    let screen = BagScreenView(
        viewModel: viewModel,
        /// A stand-in bell, so the picture shows where a real one goes: on what sold out, and
        /// nowhere else.
        stockAlertButton: { _ in AnyView(Image(systemName: "bell").frame(width: 32, height: 32)) },
        checkoutButton: AnyView(EmptyView())
    )
    return (screen, viewModel)
}

@MainActor
@Test("An empty bag says so rather than showing a blank screen")
func anEmptyBagSaysSo() {
    let (screen, _) = bagScreen(kept: Bag(), shopSays: [])

    assertSnapshot(of: screen, as: .image(layout: .device(config: .iPhone13)))
}

@MainActor
@Test("A bag the shop has changed lists what changed above lines that are already true")
func aChangedBagListsWhatChanged() async {
    let kept = Bag(items: [
        bagItem(1, price: 9.99, addedAt: Date(timeIntervalSince1970: 5)),
        bagItem(2, quantity: 2, price: 24, addedAt: Date(timeIntervalSince1970: 4)),
        bagItem(3, quantity: 5, price: 12.5, addedAt: Date(timeIntervalSince1970: 3)),
        bagItem(4, price: 7, addedAt: Date(timeIntervalSince1970: 2)),
        bagItem(5, price: 15, addedAt: Date(timeIntervalSince1970: 1))
    ])
    let (screen, viewModel) = bagScreen(kept: kept, shopSays: [
        .fixture(id: 1, price: 12.99),
        .fixture(id: 2, price: 19),
        .fixture(id: 3, price: 12.5, availability: .inStock(remaining: 2)),
        .fixture(id: 4, price: 7, availability: .outOfStock),
        .fixture(id: 5, price: 15)
    ])

    await viewModel.onAppear()

    assertSnapshot(of: screen, as: .image(layout: .device(config: .iPhone13)))
}
