//
//  BagUIDI.swift
//

import SwiftUI
import Bag
import Product
import SnackbarUI
import BagUI

public struct BagUIDI {
    private let navigation: BagNavigation
    private let observeBag: ObserveBagUseCase
    private let bagItemQuantity: BagItemQuantityUseCase
    private let addProductToBag: AddProductToBagUseCase
    private let removeProductFromBag: RemoveProductFromBagUseCase
    private let updateBagItemQuantity: UpdateBagItemQuantityUseCase
    private let getProductsByIds: GetProductsByIdsUseCase
    private let snackbarPresenter: SnackbarPresenting

    public init(
        navigation: BagNavigation,
        observeBag: ObserveBagUseCase,
        bagItemQuantity: BagItemQuantityUseCase,
        addProductToBag: AddProductToBagUseCase,
        removeProductFromBag: RemoveProductFromBagUseCase,
        updateBagItemQuantity: UpdateBagItemQuantityUseCase,
        getProductsByIds: GetProductsByIdsUseCase,
        snackbarPresenter: SnackbarPresenting
    ) {
        self.navigation = navigation
        self.observeBag = observeBag
        self.bagItemQuantity = bagItemQuantity
        self.addProductToBag = addProductToBag
        self.removeProductFromBag = removeProductFromBag
        self.updateBagItemQuantity = updateBagItemQuantity
        self.getProductsByIds = getProductsByIds
        self.snackbarPresenter = snackbarPresenter
    }

    @MainActor
    public func button(productId: Int) -> some View {
        BagButtonView(viewModel: makeButtonViewModel(productId: productId))
    }

    @MainActor
    public func detailsButton(productId: Int) -> some View {
        AddToBagButton(viewModel: makeButtonViewModel(productId: productId))
    }

    @MainActor
    public func mainView() -> some View {
        BagScreenView(
            viewModel: BagScreenViewModel(
                observeBag: observeBag,
                getProductsByIds: getProductsByIds,
                updateBagItemQuantity: updateBagItemQuantity,
                removeProductFromBag: removeProductFromBag,
                snackbar: snackbarPresenter
            ),
            navigation: navigation
        )
    }

    @MainActor
    private func makeButtonViewModel(productId: Int) -> BagButtonViewModel {
        BagButtonViewModel(
            productId: productId,
            bagItemQuantity: bagItemQuantity,
            addProductToBag: addProductToBag,
            navigation: navigation,
            snackbarPresenter: snackbarPresenter
        )
    }
}
