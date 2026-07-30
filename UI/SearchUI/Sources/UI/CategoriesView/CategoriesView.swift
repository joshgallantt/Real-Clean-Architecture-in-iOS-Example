import SwiftUI
import Product

public struct CategoriesView: View {
    let categories: [ProductCategory]
    let onSelectAll: () -> Void
    let onSelect: (ProductCategory) -> Void

    public init(
        categories: [ProductCategory],
        onSelectAll: @escaping () -> Void,
        onSelect: @escaping (ProductCategory) -> Void
    ) {
        self.categories = categories
        self.onSelectAll = onSelectAll
        self.onSelect = onSelect
    }

    public var body: some View {
        List {
            Button {
                onSelectAll()
            } label: {
                Text("All Products")
            }

            ForEach(categories) { category in
                Button {
                    onSelect(category)
                } label: {
                    Text(category.name)
                }
            }
        }
        .listStyle(.plain)
    }
}
