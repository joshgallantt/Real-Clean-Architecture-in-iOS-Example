import SwiftUI
import Product

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: a row of tappable
/// cards and nothing else. What it holds and what a tap means both arrive as arguments; how many to
/// hold is the caller's rule, not this row's.
///
/// Martin, Ch. 13 — Component Cohesion: it sits beside `ProductGridListView` because both arrange
/// the same `ProductCardView` and both change when that arrangement changes. A row that scrolled
/// differently on one tab would be a second row to keep in step with the first.
public struct ProductCardRowView: View {
    private let products: [Product]
    private let onSelect: (Product) -> Void
    private let accessory: (Product) -> AnyView
    private let leadingAccessory: (Product) -> AnyView

    /// Wide enough to read a name and a price on, narrow enough that the next card is visibly cut
    /// off — which is what tells a shopper the row scrolls without a hint saying so.
    private let cardWidth: CGFloat = 150

    public init(
        products: [Product],
        onSelect: @escaping (Product) -> Void,
        accessory: @escaping (Product) -> AnyView = { _ in AnyView(EmptyView()) },
        leadingAccessory: @escaping (Product) -> AnyView = { _ in AnyView(EmptyView()) }
    ) {
        self.products = products
        self.onSelect = onSelect
        self.accessory = accessory
        self.leadingAccessory = leadingAccessory
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(products) { product in
                    Button {
                        onSelect(product)
                    } label: {
                        ProductCardView(
                            product: product,
                            accessory: { accessory(product) },
                            leadingAccessory: { leadingAccessory(product) }
                        )
                        .frame(width: cardWidth)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        /// The row scrolls; the screen it sits on scrolls the other way. Without this the outer
        /// scroll view claims the gesture and the carousel only moves if a drag starts perfectly
        /// horizontally.
        .scrollClipDisabled()
    }
}
