import Combine
import Foundation
import Bag
import Product
import SnackbarUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class BagButtonViewModel: ObservableObject {
    @Published private(set) var quantity = 0

    private let product: Product
    private let addItemToBag: AddItemToBagUseCase
    private let navigation: BagNavigation
    private let snackbarPresenter: SnackbarPresenting
    private var cancellables = Set<AnyCancellable>()

    public init(
        product: Product,
        observeBagItemQuantity: ObserveBagItemQuantityUseCase,
        addItemToBag: AddItemToBagUseCase,
        navigation: BagNavigation,
        snackbarPresenter: SnackbarPresenting
    ) {
        self.product = product
        self.addItemToBag = addItemToBag
        self.navigation = navigation
        self.snackbarPresenter = snackbarPresenter

        observeBagItemQuantity(productId: product.id)
            .sink { [weak self] value in
                self?.quantity = value
            }
            .store(in: &cancellables)
    }

    func didTap() {
        switch product.availability {
        case .inStock:
            addToBag()
        case .outOfStock:
            snackbarPresenter.show(Snackbar(
                title: "Out of Stock",
                message: "Open it to be told when it's back.",
                icon: "shippingbox"
            ))
        case .discontinued:
            snackbarPresenter.show(Snackbar(
                title: "No Longer Available",
                message: "This isn't sold any more.",
                icon: "xmark.circle"
            ))
        }
    }

    private func addToBag() {
        addItemToBag(BagItem(productId: product.id, lastKnownPrice: product.price))

        let navigation = navigation
        snackbarPresenter.show(Snackbar(
            title: "Added to Bag",
            message: "View it any time in your bag.",
            icon: "bag.fill",
            action: .view { navigation.switchToBagTab() }
        ))
    }
}
