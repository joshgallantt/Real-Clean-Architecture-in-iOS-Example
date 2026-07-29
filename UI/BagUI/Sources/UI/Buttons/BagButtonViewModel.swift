import Combine
import Foundation
import Bag
import Product
import SnackbarUI

@MainActor
public final class BagButtonViewModel: ObservableObject {
    @Published private(set) var quantity = 0

    private let product: Product
    private let addItemToBag: AddItemToBagUseCase
    private let navigation: BagNavigation
    private let snackbarPresenter: SnackbarPresenting
    private var cancellables = Set<AnyCancellable>()

    public init(
        product: Product,
        bagItemQuantity: BagItemQuantityUseCase,
        addItemToBag: AddItemToBagUseCase,
        navigation: BagNavigation,
        snackbarPresenter: SnackbarPresenting
    ) {
        self.product = product
        self.addItemToBag = addItemToBag
        self.navigation = navigation
        self.snackbarPresenter = snackbarPresenter

        bagItemQuantity(itemId: product.id)
            .sink { [weak self] value in
                self?.quantity = value
            }
            .store(in: &cancellables)
    }

    // The boundary between the two contexts, and the only things that cross it: which
    // product, and what it costs today. The name and the picture stay where they belong,
    // in the catalog.
    //
    // Something out of stock still goes in. The shopper decided they want it; the shop
    // saying "not today" is worth mentioning, not worth refusing over. Nothing is
    // fetched, so nothing can fail.
    func didTap() {
        addItemToBag(BagItem(id: product.id, lastKnownPrice: product.price))

        let navigation = navigation
        let inStock = product.stock > 0
        snackbarPresenter.show(Snackbar(
            title: "Added to Bag",
            message: inStock
                ? "View it any time in your bag."
                : "It's out of stock right now — we'll let you know at checkout.",
            icon: inStock ? "bag.fill" : "shippingbox",
            action: .view { navigation.switchToBagTab() }
        ))
    }
}
