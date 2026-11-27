import SwiftUI
import Bag
import Product
import BagUI
import OrderUIDI
import ProductActionsUIDI
import Tracking
import TrackingUI

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
    private let bringBagUpToDate: BringBagUpToDateUseCase
    private let acknowledgeNotices: AcknowledgeNoticesUseCase

    /// The peer containers themselves, rather than closures handing this one two finished
    /// `AnyView`s.
    ///
    /// They used to be closures, so that a bag would not learn there is a stock alert domain or an
    /// order domain. What the closures actually moved was the wiring: the composition root decided
    /// which buttons, built from which use cases, while this container still decided where on the
    /// screen they went. A screen assembled in two places is assembled in neither, and the types
    /// said only `AnyView` — so nothing could tell a bell from a way to pay, here or in a test.
    ///
    /// The two dependencies are real and are now declared. A bag has a bell on its sold-out lines
    /// and a way out of itself at the bottom; `Package.swift` breaks if either stops being true.
    private let productActionsUIDI: ProductActionsUIDI
    private let orderUIDI: OrderUIDI

    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private let trackEvent: TrackEventUseCase

    public init(
        navigation: BagNavigation,
        observeBag: ObserveBagUseCase,
        observeNotices: ObserveNoticesUseCase,
        setBagItemQuantity: SetBagItemQuantityUseCase,
        bringBagUpToDate: BringBagUpToDateUseCase,
        acknowledgeNotices: AcknowledgeNoticesUseCase,
        productActionsUIDI: ProductActionsUIDI,
        orderUIDI: OrderUIDI,
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase,
        trackEvent: TrackEventUseCase
    ) {
        self.navigation = navigation
        self.observeBag = observeBag
        self.observeNotices = observeNotices
        self.setBagItemQuantity = setBagItemQuantity
        self.bringBagUpToDate = bringBagUpToDate
        self.acknowledgeNotices = acknowledgeNotices
        self.productActionsUIDI = productActionsUIDI
        self.orderUIDI = orderUIDI
        self.trackScreenView = trackScreenView
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
        self.trackEvent = trackEvent
    }

    @MainActor
    public func mainView() -> some View {
        let viewModel = BagScreenViewModel(
            navigation: navigation,
            observeBag: observeBag,
            observeNotices: observeNotices,
            setBagItemQuantity: setBagItemQuantity,
            bringBagUpToDate: bringBagUpToDate,
            acknowledgeNotices: acknowledgeNotices,
            trackScreenView: trackScreenView,
            trackElementView: trackElementView,
            trackElementInteraction: trackElementInteraction,
            trackEvent: trackEvent
        )
        return BagScreenView(
            viewModel: viewModel,
            stockAlertButton: { AnyView(productActionsUIDI.stockAlertButton(product: $0)) },
            /// The checkout names what is being bought from what this screen is drawing.
            checkoutButton: AnyView(orderUIDI.checkoutButton(products: { viewModel.products }))
        )
        .trackingScreen(BagTrackingPlan.screen)
    }
}
