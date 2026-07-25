import Foundation
import Product

@MainActor
public final class SearchTabScreenViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var isSearchActive: Bool = false
    @Published private(set) var categories: [ProductCategory] = []

    private let getCategories: GetCategoriesUseCase

    public init(getCategories: GetCategoriesUseCase) {
        self.getCategories = getCategories
    }

    func onAppear() async {
        guard categories.isEmpty else { return }
        if case .success(let value) = await getCategories() {
            categories = value
        }
    }

    func didSelectCategory(_ category: ProductCategory) {
        // Any non-navigation side effects, e.g. analytics
    }
}
