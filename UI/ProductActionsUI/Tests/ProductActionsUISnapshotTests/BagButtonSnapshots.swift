import Money
import Product
import SnapshotTesting
import SwiftUI
import Testing
@testable import ProductActionsUI
@testable import ProductActionsUITestSupport

@MainActor
@Test("The add-to-bag button invites a first tap when nothing is in the bag")
func theBagButtonInvitesAFirstTap() {
    let button = BagButtonView(
        viewModel: BagButtonViewModel(
            product: aProduct(),
            observeBagItemQuantity: StubObserveBagItemQuantity(0),
            addItemToBag: SpyAddItemToBag(),
            navigation: SpyProductActionsNavigation(),
            snackbarPresenter: SpySnackbarPresenter()
        )
    )

    assertSnapshot(of: button.frame(width: 200), as: .image(layout: .sizeThatFits))
}

@MainActor
@Test("The button shows the count once something is in the bag")
func theBagButtonShowsTheCount() {
    let button = BagButtonView(
        viewModel: BagButtonViewModel(
            product: aProduct(),
            observeBagItemQuantity: StubObserveBagItemQuantity(3),
            addItemToBag: SpyAddItemToBag(),
            navigation: SpyProductActionsNavigation(),
            snackbarPresenter: SpySnackbarPresenter()
        )
    )

    assertSnapshot(of: button.frame(width: 200), as: .image(layout: .sizeThatFits))
}

private func aProduct() -> Product {
    Product(
        id: ProductID(rawValue: 1),
        title: "Kettle",
        description: "A kettle that boils water.",
        category: CategoryID(rawValue: "home"),
        price: Money(amount: 24.99, currency: .usd),
        rating: 4.5,
        availability: .inStock(remaining: 5),
        brand: "Acme",
        thumbnail: "",
        images: []
    )
}
