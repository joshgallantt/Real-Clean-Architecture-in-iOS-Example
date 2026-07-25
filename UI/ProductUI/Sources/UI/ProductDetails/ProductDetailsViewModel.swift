import Foundation
import Product

@MainActor
public final class ProductDetailsViewModel: ObservableObject {
    @Published private(set) var product: Product?
    @Published private(set) var isLoading = false
    @Published private(set) var loadFailed = false

    private let id: Int
    private let getProduct: GetProductUseCase

    public init(id: Int, getProduct: GetProductUseCase) {
        self.id = id
        self.getProduct = getProduct
    }

    func onAppear() async {
        guard product == nil else { return }
        isLoading = true
        defer { isLoading = false }

        switch await getProduct.execute(id: id) {
        case .success(let value):
            product = value
            loadFailed = false
        case .failure:
            loadFailed = true
        }
    }
}
