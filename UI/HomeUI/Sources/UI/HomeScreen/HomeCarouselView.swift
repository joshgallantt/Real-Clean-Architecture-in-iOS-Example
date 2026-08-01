import SwiftUI
import Product
import ProductUI

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: a heading, a row of
/// cards and a way to see the rest. It decides nothing — what it holds and where View All goes both
/// arrive as arguments.
///
/// It shows the same `ProductCardView` the rest of the shop shows. A card that looked different here
/// would be a second card to keep in step with the first.
struct HomeCarouselView: View {
    let carousel: HomeCarousel
    let onSelect: (Product) -> Void
    let onViewAll: () -> Void
    let accessory: (Product) -> AnyView
    let leadingAccessory: (Product) -> AnyView

    /// Wide enough to read a name and a price on, narrow enough that the next card is visibly cut
    /// off — which is what tells a shopper the row scrolls without a hint saying so.
    private let cardWidth: CGFloat = 150

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

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(carousel.products) { product in
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
}
