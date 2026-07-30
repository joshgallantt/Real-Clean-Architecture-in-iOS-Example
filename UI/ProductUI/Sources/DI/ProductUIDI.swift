import SwiftUI
import Product
import ProductUI
import ProductActionsUIDI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds this feature's view
/// hierarchy and holds its collaborators.
///
/// Martin, Ch. 10 — Interface Segregation Principle: handed individual use cases, never a whole
/// component container. Injecting the container would be a Service Locator (Fowler, *Inversion of
/// Control Containers and the Dependency Injection Pattern* (2004)) and would blur the boundary the
/// layering exists to enforce.
public struct ProductUIDI {
    private let viewProduct: ViewProductUseCase
    private let productActionsUIDI: ProductActionsUIDI

    public init(viewProduct: ViewProductUseCase, productActionsUIDI: ProductActionsUIDI) {
        self.viewProduct = viewProduct
        self.productActionsUIDI = productActionsUIDI
    }

    @MainActor
    public func detailView(id: ProductID) -> some View {
        ProductDetailsScreen(
            viewModel: ProductDetailsViewModel(id: id, viewProduct: viewProduct),
            actionButton: { product in AnyView(productActionsUIDI.detailsActionButton(product: product)) },
            wishlistButton: AnyView(productActionsUIDI.wishlistButton(productId: id))
        )
    }

    @MainActor
    public func detailView(product: Product) -> some View {
        ProductDetailsScreen(
            viewModel: ProductDetailsViewModel(product: product),
            actionButton: { product in AnyView(productActionsUIDI.detailsActionButton(product: product)) },
            wishlistButton: AnyView(productActionsUIDI.wishlistButton(productId: product.id))
        )
    }
}
