import Foundation
import Product

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
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
