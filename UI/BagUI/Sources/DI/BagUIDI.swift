import SwiftUI
import Bag
import Product
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
    private let observeNotices: ObserveNoticesUseCase
    private let setBagItemQuantity: SetBagItemQuantityUseCase
    private let lookUpProducts: LookUpProductsUseCase
    private let bringBagUpToDate: BringBagUpToDateUseCase
    private let acknowledgeNotices: AcknowledgeNoticesUseCase
    private let stockAlertButton: (ProductID) -> AnyView
    private let checkoutButton: () -> AnyView

    public init(
        navigation: BagNavigation,
        observeBag: ObserveBagUseCase,
        observeNotices: ObserveNoticesUseCase,
        setBagItemQuantity: SetBagItemQuantityUseCase,
        lookUpProducts: LookUpProductsUseCase,
        bringBagUpToDate: BringBagUpToDateUseCase,
        acknowledgeNotices: AcknowledgeNoticesUseCase,
        stockAlertButton: @escaping (ProductID) -> AnyView,
        checkoutButton: @escaping () -> AnyView
    ) {
        self.navigation = navigation
        self.observeBag = observeBag
        self.observeNotices = observeNotices
        self.setBagItemQuantity = setBagItemQuantity
        self.lookUpProducts = lookUpProducts
        self.bringBagUpToDate = bringBagUpToDate
        self.acknowledgeNotices = acknowledgeNotices
        self.stockAlertButton = stockAlertButton
        self.checkoutButton = checkoutButton
    }

    @MainActor
    public func mainView() -> some View {
        BagScreenView(
            viewModel: BagScreenViewModel(
                navigation: navigation,
                observeBag: observeBag,
                observeNotices: observeNotices,
                lookUpProducts: lookUpProducts,
                setBagItemQuantity: setBagItemQuantity,
                bringBagUpToDate: bringBagUpToDate,
                acknowledgeNotices: acknowledgeNotices
            ),
            stockAlertButton: stockAlertButton,
            checkoutButton: checkoutButton()
        )
    }
}
