import SwiftUI
import Bag
import Product
import SnackbarUI
import BagUI

public struct BagUIDI {
    private let navigation: BagNavigation
    private let observeBag: ObserveBagUseCase
    private let observeBagChanges: ObserveBagChangesUseCase
    private let observeBagItemQuantity: ObserveBagItemQuantityUseCase
    private let addItemToBag: AddItemToBagUseCase
    private let setBagItemQuantity: SetBagItemQuantityUseCase
    private let getProductsByIds: GetProductsByIdsUseCase
    private let bringBagUpToDate: BringBagUpToDateUseCase
    private let acknowledgeBagChange: AcknowledgeBagChangeUseCase
    private let snackbarPresenter: SnackbarPresenting
    private let wishlistButton: (Int) -> AnyView

    public init(
        navigation: BagNavigation,
        observeBag: ObserveBagUseCase,
        observeBagChanges: ObserveBagChangesUseCase,
        observeBagItemQuantity: ObserveBagItemQuantityUseCase,
        addItemToBag: AddItemToBagUseCase,
        setBagItemQuantity: SetBagItemQuantityUseCase,
        getProductsByIds: GetProductsByIdsUseCase,
        bringBagUpToDate: BringBagUpToDateUseCase,
        acknowledgeBagChange: AcknowledgeBagChangeUseCase,
        snackbarPresenter: SnackbarPresenting,
        wishlistButton: @escaping (Int) -> AnyView
    ) {
        self.navigation = navigation
        self.observeBag = observeBag
        self.observeBagChanges = observeBagChanges
        self.observeBagItemQuantity = observeBagItemQuantity
        self.addItemToBag = addItemToBag
        self.setBagItemQuantity = setBagItemQuantity
        self.getProductsByIds = getProductsByIds
        self.bringBagUpToDate = bringBagUpToDate
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
                bringBagUpToDate: bringBagUpToDate,
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
            observeBagItemQuantity: observeBagItemQuantity,
            addItemToBag: addItemToBag,
            navigation: navigation,
            snackbarPresenter: snackbarPresenter
        )
    }
}
