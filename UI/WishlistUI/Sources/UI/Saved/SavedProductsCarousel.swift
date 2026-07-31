import SwiftUI
import Product
import ProductUI

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: a heading, a row of
/// cards, and a way to see the rest. It decides nothing — what it is called, what it holds and
/// where View All goes all arrive as arguments, which is what lets one carousel be both lists on
/// this tab.
///
/// It shows the same `ProductCardView` the grids show. A card that looked different here would be
/// a second card to keep in step with the first, and a shopper would have to learn it twice.
struct SavedProductsCarousel: View {
    @ObservedObject var viewModel: SavedProductsViewModel

    let title: String
    let icon: String
    let tint: Color
    let description: String
    let emptyMessage: String
    let onSelect: (Product) -> Void
    let onViewAll: () -> Void
    let accessory: (Product) -> AnyView
    let leadingAccessory: (Product) -> AnyView

    /// Wide enough to read a name and a price on, narrow enough that the next card is visibly cut
    /// off — which is what tells a shopper the row scrolls without a hint saying so.
    private let cardWidth: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SavedSectionHeader(title: title, icon: icon, tint: tint, description: description) {
                /// Only where there is more to see. A View All on a row already showing everything
                /// promises a screen the shopper has already read.
                if viewModel.savedCount > 0 {
                    Button("View All (\(viewModel.savedCount))", action: onViewAll)
                }
            }

            if viewModel.isEmpty {
                Text(emptyMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            } else {
                cards
            }
        }
    }

    private var cards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(viewModel.products) { product in
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
