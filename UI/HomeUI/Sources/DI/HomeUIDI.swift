import SwiftUI
import Home
import HomeUI
import WishlistUIDI
import ProductActionsUIDI
import Tracking
import TrackingUI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds this feature's view
/// hierarchy and holds its collaborators.
///
/// Martin, Ch. 10 — Interface Segregation Principle: handed the one use case it calls, never a whole
/// component container. Injecting the container would be a Service Locator (Fowler, *Inversion of
/// Control Containers and the Dependency Injection Pattern* (2004)) and would blur the boundary the
/// layering exists to enforce.
public struct HomeUIDI {
    private let navigation: HomeNavigation
    private let drawHomeFeed: DrawHomeFeedUseCase
    private let wishlistUIDI: WishlistUIDI
    private let productActionsUIDI: ProductActionsUIDI
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementView: TrackElementViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase

    public init(
        navigation: HomeNavigation,
        drawHomeFeed: DrawHomeFeedUseCase,
        wishlistUIDI: WishlistUIDI,
        productActionsUIDI: ProductActionsUIDI,
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase
    ) {
        self.navigation = navigation
        self.drawHomeFeed = drawHomeFeed
        self.wishlistUIDI = wishlistUIDI
        self.productActionsUIDI = productActionsUIDI
        self.trackScreenView = trackScreenView
        self.trackElementView = trackElementView
        self.trackElementInteraction = trackElementInteraction
    }

    @MainActor
    public func mainView() -> some View {
        HomeScreenView(
            viewModel: HomeScreenViewModel(
                drawHomeFeed: drawHomeFeed,
                navigation: navigation,
                trackScreenView: trackScreenView,
                trackElementView: trackElementView,
                trackElementInteraction: trackElementInteraction
            ),
            wishlistButton: { product in AnyView(wishlistUIDI.button(product: product)) },
            bagButton: { product in AnyView(productActionsUIDI.cardActionButton(product: product)) }
        )
        /// Declared here, above the screen, so the screen's own body — and every card, heart and bag
        /// button drawn inside it — reads it.
        .trackingScreen(HomeTrackingPlan.screen)
    }
}
