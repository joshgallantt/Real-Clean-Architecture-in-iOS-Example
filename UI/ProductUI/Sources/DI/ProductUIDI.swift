import SwiftUI
import Product
import ProductUI

public struct ProductUIDI {
    private let getProduct: GetProductUseCase

    public init(getProduct: GetProductUseCase) {
        self.getProduct = getProduct
    }

    @MainActor
    public func detailView(id: Int) -> some View {
        ProductDetailsScreen(
            viewModel: ProductDetailsViewModel(id: id, getProduct: getProduct)
        )
    }
}
