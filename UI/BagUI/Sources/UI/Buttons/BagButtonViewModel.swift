import Combine
import Foundation
import Bag
import SnackbarUI

@MainActor
public final class BagButtonViewModel: ObservableObject {
    @Published private(set) var quantity = 0

    private let productId: Int
    private let addProductToBag: AddProductToBagUseCase
    private let navigation: BagNavigation
    private let snackbarPresenter: SnackbarPresenting
    private var cancellables = Set<AnyCancellable>()

    public init(
        productId: Int,
        bagItemQuantity: BagItemQuantityUseCase,
        addProductToBag: AddProductToBagUseCase,
        navigation: BagNavigation,
        snackbarPresenter: SnackbarPresenting
    ) {
        self.productId = productId
        self.addProductToBag = addProductToBag
        self.navigation = navigation
        self.snackbarPresenter = snackbarPresenter

        bagItemQuantity(productId: productId)
            .sink { [weak self] value in
                self?.quantity = value
            }
            .store(in: &cancellables)
    }

    func didTap() {
        Task { [weak self] in
            await self?.add()
        }
    }

    // Capture dependencies, not self: the snackbar action closure escapes this call
    // and must not keep a discarded grid cell's view model alive.

    private func add() async {
        let addProductToBag = addProductToBag
        let navigation = navigation
        let snackbarPresenter = snackbarPresenter
        let productId = productId

        switch await addProductToBag(productId: productId) {
        case .success:
            snackbarPresenter.show(Snackbar(
                title: "Added to Bag",
                message: "View it any time in your bag.",
                icon: "bag.fill",
                action: .view { navigation.switchToBagTab() }
            ))
        case .failure(.network):
            snackbarPresenter.show(Snackbar(
                title: "Couldn't Add to Bag",
                message: "Check your connection and try again.",
                icon: "wifi.slash",
                action: .retry { [weak self] in Task { await self?.add() } }
            ))
        }
    }
}
