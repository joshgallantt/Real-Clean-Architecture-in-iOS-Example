import SwiftUI
import Product
import ProductUI

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: a heading, a row of
/// cards and a way to see the rest. It decides nothing — what it holds and where View All goes both
/// arrive as arguments.
///
/// It shows the same `ProductCardRowView` the wishlist tab shows, of the same `ProductCardView` the
/// rest of the shop shows. A card or a row that looked different here would be a second of each to
/// keep in step with the first.
struct HomeCarouselView: View {
    let carousel: HomeCarousel
    let onSelect: (Product) -> Void
    let onViewAll: () -> Void
    let accessory: (Product) -> AnyView
    let leadingAccessory: (Product) -> AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(carousel.category.name)
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("View All", action: onViewAll)
                    .font(.subheadline)
            }
            .padding(.horizontal)

            ProductCardRowView(
                products: carousel.products,
                onSelect: onSelect,
                accessory: accessory,
                leadingAccessory: leadingAccessory
            )
        }
    }
}
