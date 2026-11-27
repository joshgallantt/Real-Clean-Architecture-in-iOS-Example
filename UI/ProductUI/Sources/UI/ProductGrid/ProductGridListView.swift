import SwiftUI
import Product
import Tracking
import TrackingUI

public struct ProductGridListView: View {
    private let products: [Product]
    private let isLoadingMore: Bool
    private let onSelect: (Product, TrackingContext) -> Void
    private let onSeen: (Product, TrackingContext) -> Void
    private let onCardAppear: (Product) -> Void
    private let accessory: (Product) -> AnyView
    private let leadingAccessory: (Product) -> AnyView

    private let columns = [
        GridItem(.flexible(), spacing: 16, alignment: .top),
        GridItem(.flexible(), spacing: 16, alignment: .top)
    ]

    public init(
        products: [Product],
        isLoadingMore: Bool,
        onSelect: @escaping (Product, TrackingContext) -> Void,
        onSeen: @escaping (Product, TrackingContext) -> Void,
        onCardAppear: @escaping (Product) -> Void,
        accessory: @escaping (Product) -> AnyView,
        leadingAccessory: @escaping (Product) -> AnyView
    ) {
        self.products = products
        self.isLoadingMore = isLoadingMore
        self.onSelect = onSelect
        self.onSeen = onSeen
        self.onCardAppear = onCardAppear
        self.accessory = accessory
        self.leadingAccessory = leadingAccessory
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                    TrackedProductCard(
                        product: product,
                        onSelect: onSelect,
                        onSeen: onSeen,
                        accessory: accessory,
                        leadingAccessory: leadingAccessory
                    )
                    .trackingPosition(index)
                    /// Built, not seen: what to fetch next is decided by whoever owns the list, which
                    /// is told about every card as it is laid out and can tell the last one from
                    /// the rest itself.
                    .onAppear { onCardAppear(product) }
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
