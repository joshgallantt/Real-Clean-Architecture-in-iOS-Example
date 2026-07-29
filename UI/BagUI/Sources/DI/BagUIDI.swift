import SwiftUI
import Bag
import Product
import SnackbarUI
import BagUI

public struct BagUIDI {
    private let navigation: BagNavigation
    private let observeBag: ObserveBagUseCase
    private let bagItemQuantity: BagItemQuantityUseCase
    private let addItemToBag: AddItemToBagUseCase
    private let setBagItemQuantity: SetBagItemQuantityUseCase
    private let getProductsByIds: GetProductsByIdsUseCase
    private let reconcileBag: ReconcileBagUseCase
    private let acknowledgeBagChange: AcknowledgeBagChangeUseCase
    private let snackbarPresenter: SnackbarPresenting

    public init(
        navigation: BagNavigation,
        observeBag: ObserveBagUseCase,
        bagItemQuantity: BagItemQuantityUseCase,
        addItemToBag: AddItemToBagUseCase,
        setBagItemQuantity: SetBagItemQuantityUseCase,
        getProductsByIds: GetProductsByIdsUseCase,
        reconcileBag: ReconcileBagUseCase,
        acknowledgeBagChange: AcknowledgeBagChangeUseCase,
        snackbarPresenter: SnackbarPresenting
    ) {
        self.navigation = navigation
        self.observeBag = observeBag
        self.bagItemQuantity = bagItemQuantity
        self.addItemToBag = addItemToBag
        self.setBagItemQuantity = setBagItemQuantity
        self.getProductsByIds = getProductsByIds
        self.reconcileBag = reconcileBag
        self.acknowledgeBagChange = acknowledgeBagChange
        self.snackbarPresenter = snackbarPresenter
    }

    @MainActor
    public func button(product: Product) -> some View {
        BagButtonView(viewModel: makeButtonViewModel(product: product))
    }

    @MainActor
    public func detailsButton(product: Product) -> some View {
        AddToBagButton(viewModel: makeButtonViewModel(product: product))
    }

    @MainActor
    public func mainView() -> some View {
        BagScreenView(
            viewModel: BagScreenViewModel(
                observeBag: observeBag,
                getProductsByIds: getProductsByIds,
                setBagItemQuantity: setBagItemQuantity,
                reconcileBag: reconcileBag,
                acknowledgeBagChange: acknowledgeBagChange
            ),
            navigation: navigation
        )
    }

    @MainActor
    private func makeButtonViewModel(product: Product) -> BagButtonViewModel {
        BagButtonViewModel(
            product: product,
            bagItemQuantity: bagItemQuantity,
            addItemToBag: addItemToBag,
            navigation: navigation,
            snackbarPresenter: snackbarPresenter
        )
    }
}
