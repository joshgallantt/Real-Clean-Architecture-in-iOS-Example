import SwiftUI
import Home
import HomeUI
import WishlistUIDI
import ProductActionsUIDI

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

    public init(
        navigation: HomeNavigation,
        drawHomeFeed: DrawHomeFeedUseCase,
        wishlistUIDI: WishlistUIDI,
        productActionsUIDI: ProductActionsUIDI
    ) {
        self.navigation = navigation
        self.drawHomeFeed = drawHomeFeed
        self.wishlistUIDI = wishlistUIDI
        self.productActionsUIDI = productActionsUIDI
    }

    @MainActor
    public func mainView() -> some View {
        HomeScreenView(
            viewModel: HomeScreenViewModel(drawHomeFeed: drawHomeFeed, navigation: navigation),
            wishlistButton: { id in AnyView(wishlistUIDI.button(productId: id)) },
            bagButton: { product in AnyView(productActionsUIDI.cardActionButton(product: product)) }
        )
    }
}
