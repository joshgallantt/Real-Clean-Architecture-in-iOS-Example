import SwiftUI
import Bag
import Product
import SnackbarUI
import BagUI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds this feature's view
/// hierarchy and holds its collaborators.
///
/// Martin, Ch. 10 — Interface Segregation Principle: handed individual use cases, never a whole
/// component container. Injecting the container would be a Service Locator (Fowler, *Inversion of
/// Control Containers and the Dependency Injection Pattern* (2004)) and would blur the boundary the
/// layering exists to enforce.
public struct BagUIDI {
    private let navigation: BagNavigation
    private let observeBag: ObserveBagUseCase
    private let observeBagChanges: ObserveBagChangesUseCase
    private let observeBagItemQuantity: ObserveBagItemQuantityUseCase
    private let addItemToBag: AddItemToBagUseCase
    private let setBagItemQuantity: SetBagItemQuantityUseCase
    private let lookUpProducts: LookUpProductsUseCase
    private let bringBagUpToDate: BringBagUpToDateUseCase
    private let acknowledgeBagChange: AcknowledgeBagChangeUseCase
    private let snackbarPresenter: SnackbarPresenting
    private let wishlistButton: (ProductID) -> AnyView

    public init(
        navigation: BagNavigation,
        observeBag: ObserveBagUseCase,
        observeBagChanges: ObserveBagChangesUseCase,
        observeBagItemQuantity: ObserveBagItemQuantityUseCase,
        addItemToBag: AddItemToBagUseCase,
        setBagItemQuantity: SetBagItemQuantityUseCase,
        lookUpProducts: LookUpProductsUseCase,
        bringBagUpToDate: BringBagUpToDateUseCase,
        acknowledgeBagChange: AcknowledgeBagChangeUseCase,
        snackbarPresenter: SnackbarPresenting,
        wishlistButton: @escaping (ProductID) -> AnyView
    ) {
        self.navigation = navigation
        self.observeBag = observeBag
        self.observeBagChanges = observeBagChanges
        self.observeBagItemQuantity = observeBagItemQuantity
        self.addItemToBag = addItemToBag
        self.setBagItemQuantity = setBagItemQuantity
        self.lookUpProducts = lookUpProducts
        self.bringBagUpToDate = bringBagUpToDate
        self.acknowledgeBagChange = acknowledgeBagChange
        self.snackbarPresenter = snackbarPresenter
        self.wishlistButton = wishlistButton
    }

    @MainActor
    public func button(product: Product) -> some View {
        BagButtonView(viewModel: makeButtonViewModel(product: product))
    }

    @MainActor
    @ViewBuilder
    public func detailsButton(product: Product) -> some View {
        switch product.availability {
        case .inStock:
            AddToBagButton(viewModel: makeButtonViewModel(product: product))
        case .outOfStock:
            NotifyMeButton(product: product, snackbarPresenter: snackbarPresenter)
        case .discontinued:
            UnavailableButton()
        }
    }

    @MainActor
    public func mainView() -> some View {
        BagScreenView(
            viewModel: BagScreenViewModel(
                observeBag: observeBag,
                observeBagChanges: observeBagChanges,
                lookUpProducts: lookUpProducts,
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
