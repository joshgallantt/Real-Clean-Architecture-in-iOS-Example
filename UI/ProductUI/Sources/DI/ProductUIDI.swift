import SwiftUI
import Product
import ProductUI
import BagUIDI

public struct ProductUIDI {
    private let getProduct: GetProductUseCase
    private let bagUIDI: BagUIDI

    public init(getProduct: GetProductUseCase, bagUIDI: BagUIDI) {
        self.getProduct = getProduct
        self.bagUIDI = bagUIDI
    }

    @MainActor
    public func detailView(id: Int) -> some View {
        ProductDetailsScreen(
            viewModel: ProductDetailsViewModel(id: id, getProduct: getProduct),
            actionButton: AnyView(bagUIDI.detailsButton(productId: id))
        )
    }
}
