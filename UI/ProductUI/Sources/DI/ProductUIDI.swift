import SwiftUI
import Product
import ProductUI
import BagUIDI
import SharedUIDI

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
