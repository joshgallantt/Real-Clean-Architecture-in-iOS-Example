import Foundation
import Product

@MainActor
public final class ProductDetailsViewModel: ObservableObject {
    @Published private(set) var product: Product?
    @Published private(set) var isLoading = false
    @Published private(set) var loadFailed = false

    private let id: ProductID
    private let viewProduct: ViewProductUseCase?

    public init(id: ProductID, viewProduct: ViewProductUseCase) {
        self.id = id
        self.viewProduct = viewProduct
    }

    // Skips the fetch entirely: the caller already holds the full model (e.g.
    // a product grid), so there's nothing to load.
    public init(product: Product) {
        self.id = product.id
        self.product = product
        self.viewProduct = nil
    }

    func onAppear() async {
        guard product == nil, let viewProduct else { return }
        isLoading = true
        defer { isLoading = false }

        switch await viewProduct(id: id) {
        case .success(let value):
            product = value
            loadFailed = false
        case .failure:
            loadFailed = true
        }
    }
}
