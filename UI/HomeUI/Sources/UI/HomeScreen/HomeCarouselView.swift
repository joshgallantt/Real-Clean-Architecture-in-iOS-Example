import SwiftUI
import Home
import Product
import ProductUI
import Tracking
import TrackingUI

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: a heading, a row of
/// cards and a way to see the rest. It decides nothing — what it holds and where View All goes both
/// arrive as arguments.
///
/// It shows the same `ProductCardRowView` the wishlist tab shows, of the same `ProductCardView` the
/// rest of the shop shows. A card or a row that looked different here would be a second of each to
/// keep in step with the first.
///
/// It sits inside the carousel's list but at no position in it, so View All reports against the
/// screen — a heading is not one of the cards.
struct HomeCarouselView: View {
    @Environment(\.trackingContext) private var trackingContext

    let carousel: HomeCarousel
    let onSelect: (Product, TrackingContext) -> Void
    let onSeen: (Product, TrackingContext) -> Void
    let onViewAll: (TrackingContext) -> Void
    let accessory: (Product) -> AnyView
    let leadingAccessory: (Product) -> AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(carousel.category.name)
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("View All") { onViewAll(trackingContext) }
                    .font(.subheadline)
            }
            .padding(.horizontal)

            ProductCardRowView(
                products: carousel.products,
                onSelect: onSelect,
                onSeen: onSeen,
                accessory: accessory,
                leadingAccessory: leadingAccessory
            )
        }
    }
}
