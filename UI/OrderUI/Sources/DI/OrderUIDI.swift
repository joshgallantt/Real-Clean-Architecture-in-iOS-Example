import SwiftUI
import Bag
import Order
import Product
import AuthUI
import OrderUI
import SheetUI
import SnackbarUI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds this feature's views and
/// holds its collaborators.
///
/// Martin, Ch. 10 — Interface Segregation Principle: handed individual use cases, never a whole
/// component container. Injecting the container would be a Service Locator (Fowler, *Inversion of
/// Control Containers and the Dependency Injection Pattern* (2004)) and would blur the boundary the
/// layering exists to enforce.
public struct OrderUIDI {
    private let placeOrder: PlaceOrderUseCase
    private let observeOrders: ObserveOrdersUseCase
    private let observeBag: ObserveBagUseCase
    private let setBagItemQuantity: SetBagItemQuantityUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private let sheetPresenter: SheetPresenting

    public init(
        placeOrder: PlaceOrderUseCase,
        observeOrders: ObserveOrdersUseCase,
        observeBag: ObserveBagUseCase,
        setBagItemQuantity: SetBagItemQuantityUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting,
        sheetPresenter: SheetPresenting
    ) {
        self.placeOrder = placeOrder
        self.observeOrders = observeOrders
        self.observeBag = observeBag
        self.setBagItemQuantity = setBagItemQuantity
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter
        self.sheetPresenter = sheetPresenter
    }

    @MainActor
    public func buyNowButton(product: Product) -> some View {
        BuyNowButton(
            viewModel: BuyNowButtonViewModel(
                product: product,
                placeOrder: placeOrder,
                authPresenter: authPresenter,
                snackbarPresenter: snackbarPresenter,
                confirm: confirm
            )
        )
    }

    @MainActor
    public func checkoutButton() -> some View {
        CheckoutButton(
            viewModel: CheckoutButtonViewModel(
                observeBag: observeBag,
                placeOrder: placeOrder,
                setBagItemQuantity: setBagItemQuantity,
                authPresenter: authPresenter,
                snackbarPresenter: snackbarPresenter,
                confirm: confirm
            )
        )
    }

    @MainActor
    public func historyView() -> some View {
        OrderHistoryScreen(viewModel: OrderHistoryViewModel(observeOrders: observeOrders))
    }

    /// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle: the view models
    /// are handed a closure that takes an order, so neither of them imports SwiftUI or learns how a
    /// confirmation gets on screen.
    ///
    /// It goes through the app's sheet host rather than a `.sheet` on the button, because checking
    /// out empties the bag — the button that started it is gone by the time the confirmation would
    /// appear, and a sheet anchored to it would go with it.
    @MainActor
    private var confirm: (Order) -> Void {
        { order in
            sheetPresenter.present {
                OrderConfirmationView(order: order) { sheetPresenter.dismiss() }
            }
        }
    }
}
