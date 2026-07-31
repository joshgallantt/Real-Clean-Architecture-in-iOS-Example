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

    /// A closure rather than `OrderUIDI`, unlike the peer container above it. `ProductActionsUIDI`
    /// is named here because a product's buttons are part of what this screen *is*; a way to pay is
    /// not, and taking the container would put the order domain in this package's dependency list
    /// for the sake of one button.
    private let buyNowButton: (Product) -> AnyView

    public init(
        viewProduct: ViewProductUseCase,
        productActionsUIDI: ProductActionsUIDI,
        buyNowButton: @escaping (Product) -> AnyView
    ) {
        self.viewProduct = viewProduct
        self.productActionsUIDI = productActionsUIDI
        self.buyNowButton = buyNowButton
    }

    @MainActor
    public func detailView(id: ProductID) -> some View {
        ProductDetailsScreen(
            viewModel: ProductDetailsViewModel(id: id, viewProduct: viewProduct),
            actionButton: { product in AnyView(productActionsUIDI.detailsActionButton(product: product)) },
            wishlistButton: AnyView(productActionsUIDI.wishlistButton(productId: id)),
            buyNowButton: buyNowButton
        )
    }

    @MainActor
    public func detailView(product: Product) -> some View {
        ProductDetailsScreen(
            viewModel: ProductDetailsViewModel(product: product),
            actionButton: { product in AnyView(productActionsUIDI.detailsActionButton(product: product)) },
            wishlistButton: AnyView(productActionsUIDI.wishlistButton(productId: product.id)),
            buyNowButton: buyNowButton
        )
    }
}
