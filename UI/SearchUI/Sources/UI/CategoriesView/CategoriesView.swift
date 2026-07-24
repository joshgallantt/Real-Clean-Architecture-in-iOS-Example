import SwiftUI
import Product

public struct CategoriesView: View {
    let categories: [ProductCategory]
    let onSelect: (ProductCategory) -> Void

    public init(categories: [ProductCategory], onSelect: @escaping (ProductCategory) -> Void) {
        self.categories = categories
        self.onSelect = onSelect
    }

    public var body: some View {
        List(categories) { category in
            Button {
                onSelect(category)
            } label: {
                Text(category.name)
            }
        }
        .listStyle(.plain)
    }
}
