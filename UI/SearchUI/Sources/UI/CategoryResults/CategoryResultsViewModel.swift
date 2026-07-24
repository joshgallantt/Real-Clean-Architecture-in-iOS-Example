import Foundation
import Product

@MainActor
public final class CategoryResultsViewModel: ObservableObject {
    let category: CategorySlug
    @Published private(set) var results: [Product] = []
    @Published private(set) var isLoading = false

    private let getProducts: GetProductsUseCase

    public init(category: CategorySlug, getProducts: GetProductsUseCase) {
        self.category = category
        self.getProducts = getProducts
    }

    var displayName: String {
        category.value.replacingOccurrences(of: "-", with: " ").capitalized
    }

    func onAppear() async {
        guard results.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        if case .success(let value) = await getProducts.execute(matching: .category(category, page: 0, pageSize: 30)) {
            results = value
        }
    }

    func didSelect(_ product: Product) {
        // Any non-navigation side effects, e.g. analytics
    }
}
