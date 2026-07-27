import SwiftUI
import Product
import ProductUI
import BagUIDI
import SharedUIDI

public struct ProductUIDI {
    private let getProduct: GetProductUseCase
    private let bagUIDI: BagUIDI
    private let sharedUIDI: SharedUIDI

    public init(getProduct: GetProductUseCase, bagUIDI: BagUIDI, sharedUIDI: SharedUIDI) {
        self.getProduct = getProduct
        self.bagUIDI = bagUIDI
        self.sharedUIDI = sharedUIDI
    }

    @MainActor
    public func detailView(id: Int) -> some View {
        ProductDetailsScreen(
            viewModel: ProductDetailsViewModel(id: id, getProduct: getProduct),
            actionButton: AnyView(bagUIDI.detailsButton(productId: id)),
            wishlistButton: AnyView(sharedUIDI.wishlistButton(productId: id))
        )
    }

    @MainActor
    public func detailView(product: Product) -> some View {
        ProductDetailsScreen(
            viewModel: ProductDetailsViewModel(product: product),
            actionButton: AnyView(bagUIDI.detailsButton(productId: product.id)),
            wishlistButton: AnyView(sharedUIDI.wishlistButton(productId: product.id))
        )
    }
}
