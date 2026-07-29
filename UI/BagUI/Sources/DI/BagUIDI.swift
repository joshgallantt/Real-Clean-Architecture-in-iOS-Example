import SwiftUI
import Bag
import Product
import SnackbarUI
import BagUI

public struct BagUIDI {
    private let navigation: BagNavigation
    private let observeBag: ObserveBagUseCase
    private let observeBagChanges: ObserveBagChangesUseCase
    private let bagItemQuantity: BagItemQuantityUseCase
    private let addItemToBag: AddItemToBagUseCase
    private let setBagItemQuantity: SetBagItemQuantityUseCase
    private let getProductsByIds: GetProductsByIdsUseCase
    private let reconcileBag: ReconcileBagUseCase
    private let acknowledgeBagChange: AcknowledgeBagChangeUseCase
    private let snackbarPresenter: SnackbarPresenting
    private let wishlistButton: (Int) -> AnyView

    public init(
        navigation: BagNavigation,
        observeBag: ObserveBagUseCase,
        observeBagChanges: ObserveBagChangesUseCase,
        bagItemQuantity: BagItemQuantityUseCase,
        addItemToBag: AddItemToBagUseCase,
        setBagItemQuantity: SetBagItemQuantityUseCase,
        getProductsByIds: GetProductsByIdsUseCase,
        reconcileBag: ReconcileBagUseCase,
        acknowledgeBagChange: AcknowledgeBagChangeUseCase,
        snackbarPresenter: SnackbarPresenting,
        wishlistButton: @escaping (Int) -> AnyView
    ) {
        self.navigation = navigation
        self.observeBag = observeBag
        self.observeBagChanges = observeBagChanges
        self.bagItemQuantity = bagItemQuantity
        self.addItemToBag = addItemToBag
        self.setBagItemQuantity = setBagItemQuantity
        self.getProductsByIds = getProductsByIds
        self.reconcileBag = reconcileBag
        self.acknowledgeBagChange = acknowledgeBagChange
        self.snackbarPresenter = snackbarPresenter
        self.wishlistButton = wishlistButton
    }

    @MainActor
    public func button(product: Product) -> some View {
        BagButtonView(viewModel: makeButtonViewModel(product: product))
    }

    /// What a shopper can do about a product they are looking at. Something in stock can
    /// be bagged; something coming back can be waited for; something gone offers nothing.
    @MainActor
    @ViewBuilder
    public func detailsButton(product: Product) -> some View {
        if product.isInStock {
            AddToBagButton(viewModel: makeButtonViewModel(product: product))
        } else if product.willRestock {
            NotifyMeButton(product: product, snackbarPresenter: snackbarPresenter)
        } else {
            UnavailableButton()
        }
    }

    @MainActor
    public func mainView() -> some View {
        BagScreenView(
            viewModel: BagScreenViewModel(
                observeBag: observeBag,
                observeBagChanges: observeBagChanges,
                getProductsByIds: getProductsByIds,
                setBagItemQuantity: setBagItemQuantity,
                reconcileBag: reconcileBag,
                acknowledgeBagChange: acknowledgeBagChange,
                snackbar: snackbarPresenter
            ),
            navigation: navigation,
            wishlistButton: wishlistButton
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
