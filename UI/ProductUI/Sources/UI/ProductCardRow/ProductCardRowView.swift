import SwiftUI
import Product
import Tracking
import TrackingUI

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: a row of tappable
/// cards and nothing else. What it holds, what a tap means and what being seen means all arrive as
/// arguments; how many to hold is the caller's rule, not this row's.
///
/// Each card is placed at its position in the row, counted from 0, and hands the context it was
/// tapped or seen in to the caller. Which list this is — and so what the position is a position
/// in — is the caller's to say, with `.trackingList` above the row.
///
/// Martin, Ch. 13 — Component Cohesion: it sits beside `ProductGridListView` because both arrange
/// the same `ProductCardView` and both change when that arrangement changes. A row that scrolled
/// differently on one tab would be a second row to keep in step with the first.
public struct ProductCardRowView: View {
    private let products: [Product]
    private let onSelect: (Product, TrackingContext) -> Void
    private let onSeen: (Product, TrackingContext) -> Void
    private let accessory: (Product) -> AnyView
    private let leadingAccessory: (Product) -> AnyView

    /// Wide enough to read a name and a price on, narrow enough that the next card is visibly cut
    /// off — which is what tells a shopper the row scrolls without a hint saying so.
    private let cardWidth: CGFloat = 150

    public init(
        products: [Product],
        onSelect: @escaping (Product, TrackingContext) -> Void,
        onSeen: @escaping (Product, TrackingContext) -> Void,
        accessory: @escaping (Product) -> AnyView,
        leadingAccessory: @escaping (Product) -> AnyView
    ) {
        self.products = products
        self.onSelect = onSelect
        self.onSeen = onSeen
        self.accessory = accessory
        self.leadingAccessory = leadingAccessory
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                    TrackedProductCard(
                        product: product,
                        onSelect: onSelect,
                        onSeen: onSeen,
                        accessory: accessory,
                        leadingAccessory: leadingAccessory
                    )
                    .frame(width: cardWidth)
                    .trackingPosition(index)
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
