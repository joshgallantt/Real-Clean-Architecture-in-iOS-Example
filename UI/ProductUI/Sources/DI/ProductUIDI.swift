import SwiftUI
import Product
import ProductUI
import OrderUIDI
import ProductActionsUIDI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds this feature's view
/// hierarchy and holds its collaborators.
///
/// Martin, Ch. 10 — Interface Segregation Principle: handed individual use cases, never a whole
/// component container. Injecting the container would be a Service Locator (Fowler, *Inversion of
/// Control Containers and the Dependency Injection Pattern* (2004)) and would blur the boundary the
/// layering exists to enforce.
public struct ProductUIDI {
    private let productActionsUIDI: ProductActionsUIDI

    /// `OrderUIDI` itself, like the peer container above it, rather than a closure handing this one
    /// a finished `AnyView`.
    ///
    /// It used to be a closure, on the grounds that a way to pay is not part of what a product page
    /// *is* and should not reach this package's dependency list for the sake of one button. What
    /// the closure actually moved was the wiring: the composition root decided which button, built
    /// from which use cases, while this container still decided where on the page it went. A screen
    /// assembled in two places is assembled in neither, and the type said only `AnyView` — so
    /// nothing could tell a buy button from any other view, here or in a test.
    ///
    /// The dependency it was avoiding is a real one and it is now declared, which is the point: the
    /// package list says a product page can be bought from, and `Package.swift` breaks if that ever
    /// stops being true.
    private let orderUIDI: OrderUIDI

    public init(
        productActionsUIDI: ProductActionsUIDI,
        orderUIDI: OrderUIDI
    ) {
        self.productActionsUIDI = productActionsUIDI
        self.orderUIDI = orderUIDI
    }

    /// A product, never an id. Every route to this screen already holds the thing it is about —
    /// see `Destination` — so there is no second way in that would have to go and fetch one, and
    /// no loading or not-found state to draw for a page that cannot arrive empty.
    @MainActor
    public func detailView(product: Product) -> some View {
        ProductDetailsScreen(
            viewModel: ProductDetailsViewModel(product: product),
            actionButton: { product in AnyView(productActionsUIDI.detailsActionButton(product: product)) },
            wishlistButton: AnyView(productActionsUIDI.wishlistButton(productId: product.id)),
            buyNowButton: { AnyView(orderUIDI.buyNowButton(product: $0)) }
        )
    }
}
