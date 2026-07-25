import Combine
import Foundation
import Product

@MainActor
public final class HomeScreenViewModel: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false

    private let getProducts: GetProductsUseCase

    public init(getProducts: GetProductsUseCase) {
        self.getProducts = getProducts
    }

    func onAppear() async {
        guard products.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        if case .success(let value) = await getProducts(matching: .all(page: 0, pageSize: 30)) {
            products = value
        }
    }

    func didSelect(_ product: Product) {
        // Any non-navigation side effects, e.g. analytics
    }
}
