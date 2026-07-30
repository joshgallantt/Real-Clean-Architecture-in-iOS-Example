import SwiftUI
import Product
import ProductUI
import BagUIDI
import SharedUIDI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds this feature's view
/// hierarchy and holds its collaborators.
///
/// Martin, Ch. 10 — Interface Segregation Principle: handed individual use cases, never a whole
/// component container. Injecting the container would be a Service Locator (Fowler, *Inversion of
/// Control Containers and the Dependency Injection Pattern* (2004)) and would blur the boundary the
/// layering exists to enforce.
public struct ProductUIDI {
    private let viewProduct: ViewProductUseCase
    private let bagUIDI: BagUIDI
    private let sharedUIDI: SharedUIDI

    public init(viewProduct: ViewProductUseCase, bagUIDI: BagUIDI, sharedUIDI: SharedUIDI) {
        self.viewProduct = viewProduct
        self.bagUIDI = bagUIDI
        self.sharedUIDI = sharedUIDI
    }

    @MainActor
    public func detailView(id: ProductID) -> some View {
        ProductDetailsScreen(
            viewModel: ProductDetailsViewModel(id: id, viewProduct: viewProduct),
            actionButton: { product in AnyView(bagUIDI.detailsButton(product: product)) },
            wishlistButton: AnyView(sharedUIDI.wishlistButton(productId: id))
        )
    }

    @MainActor
    public func detailView(product: Product) -> some View {
        ProductDetailsScreen(
            viewModel: ProductDetailsViewModel(product: product),
            actionButton: { product in AnyView(bagUIDI.detailsButton(product: product)) },
            wishlistButton: AnyView(sharedUIDI.wishlistButton(productId: product.id))
        )
    }
}
