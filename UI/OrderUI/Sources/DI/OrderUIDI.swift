import SwiftUI
import Bag
import Order
import Product
import AuthUI
import OrderUI
import SheetUI
import SnackbarUI
import Tracking
import TrackingUI

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
    private let setBagItem: SetBagItemUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private let sheetPresenter: SheetPresenting
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private let trackEvent: TrackEventUseCase

    public init(
        placeOrder: PlaceOrderUseCase,
        observeOrders: ObserveOrdersUseCase,
        setBagItem: SetBagItemUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting,
        sheetPresenter: SheetPresenting,
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase,
        trackEvent: TrackEventUseCase
    ) {
        self.placeOrder = placeOrder
        self.observeOrders = observeOrders
        self.setBagItem = setBagItem
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter
        self.sheetPresenter = sheetPresenter
        self.trackScreenView = trackScreenView
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
        self.trackEvent = trackEvent
    }

    /// Where it is drawn is in the environment it is drawn into, like every product button's.
    @MainActor
    public func buyNowButton(product: Product) -> some View {
        BuyNowButton(
            viewModel: BuyNowButtonViewModel(
                product: product,
                placeOrder: placeOrder,
                authPresenter: authPresenter,
                snackbarPresenter: snackbarPresenter,
                confirm: confirm,
                trackScreenView: trackScreenView,
                trackElementView: trackElementView,
                trackElementInteraction: trackElementInteraction,
                trackEvent: trackEvent
            )
        )
    }

    /// `bag` is the bag as the screen is drawing it, so a checkout buys what the shopper is looking
    /// at, at the prices shown. `products` is what that screen has been told, so a checkout can say
    /// what was bought by name. The button never looks the catalog up itself: the screen it sits on
    /// already has.
    @MainActor
    public func checkoutButton(
        bag: @escaping @MainActor () -> Bag,
        products: @escaping @MainActor () -> [ProductID: Product]
    ) -> some View {
        CheckoutButton(
            viewModel: CheckoutButtonViewModel(
                bag: bag,
                placeOrder: placeOrder,
                setBagItem: setBagItem,
                authPresenter: authPresenter,
                snackbarPresenter: snackbarPresenter,
                confirm: confirm,
                products: products,
                trackScreenView: trackScreenView,
                trackElementView: trackElementView,
                trackElementInteraction: trackElementInteraction,
                trackEvent: trackEvent
            )
        )
    }

    @MainActor
    public func historyView() -> some View {
        OrderHistoryScreen(viewModel: OrderHistoryViewModel(observeOrders: observeOrders, trackScreenView: trackScreenView))
            .trackingScreen(OrderTrackingPlan.history)
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
                OrderConfirmationView(viewModel: OrderConfirmationViewModel(
                    order: OrderSummary(order),
                    done: { sheetPresenter.dismiss() },
                    trackScreenView: trackScreenView,
                    trackElementInteraction: trackElementInteraction
                ))
                /// Presented by the app's sheet host, above every screen, so nothing above it says
                /// where it is: it says so itself.
                .trackingScreen(OrderTrackingPlan.confirmation)
            }
        }
    }
}
