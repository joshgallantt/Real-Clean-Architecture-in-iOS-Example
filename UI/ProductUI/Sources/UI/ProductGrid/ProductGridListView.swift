import SwiftUI
import UIKit
import Product

public struct ProductGridListView: View {
    private let products: [Product]
    private let isLoadingMore: Bool
    private let onSelect: (Product) -> Void
    private let onReachEnd: () -> Void
    private let accessory: (Product) -> AnyView
    private let leadingAccessory: (Product) -> AnyView

    private let columns = [
        GridItem(.flexible(), spacing: 16, alignment: .top),
        GridItem(.flexible(), spacing: 16, alignment: .top)
    ]

    public init(
        products: [Product],
        isLoadingMore: Bool,
        onSelect: @escaping (Product) -> Void,
        onReachEnd: @escaping () -> Void,
        accessory: @escaping (Product) -> AnyView = { _ in AnyView(EmptyView()) },
        leadingAccessory: @escaping (Product) -> AnyView = { _ in AnyView(EmptyView()) }
    ) {
        self.products = products
        self.isLoadingMore = isLoadingMore
        self.onSelect = onSelect
        self.onReachEnd = onReachEnd
        self.accessory = accessory
        self.leadingAccessory = leadingAccessory
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(products) { product in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onSelect(product)
                    } label: {
                        ProductCardView(
                            product: product,
                            accessory: { accessory(product) },
                            leadingAccessory: { leadingAccessory(product) }
                        )
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if product.id == products.last?.id {
                            onReachEnd()
                        }
                    }
                }
            }
            .padding()

            if isLoadingMore {
                ProgressView()
                    .padding(.vertical)
            }
        }
    }
}
