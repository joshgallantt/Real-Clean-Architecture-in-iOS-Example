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

    @State private var isConfirmingClear = false

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

    /// A row is a sample, not the list. Ten is far more than anybody scrolls sideways through, and
    /// View All is right there for the rest — so the tab stays a summary of three things rather
    /// than three lists a shopper has to get past.
    private let atMost = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SavedSectionHeader(title: title, icon: icon, tint: tint, description: description) {
                /// Nothing to offer about an empty list: neither seeing the rest of it nor emptying
                /// it means anything, and two disabled buttons say less than no buttons.
                if viewModel.savedCount > 0 {
                    HStack(spacing: 12) {
                        Button("View All (\(viewModel.savedCount))", action: onViewAll)

                        /// Red, because it is the only thing in this heading that takes something
                        /// away — and asked about first, because there is no undo behind it.
                        Button("Clear", role: .destructive) { isConfirmingClear = true }
                            .foregroundStyle(.red)
                    }
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
        /// On the carousel rather than offered as something the caller must remember to attach.
        /// A Clear whose confirmation can be left off is a Clear that one day deletes without
        /// asking.
        .confirmationDialog(
            "Clear \(title)?",
            isPresented: $isConfirmingClear,
            titleVisibility: .visible
        ) {
            Button("Clear \(title)", role: .destructive) { viewModel.didConfirmClear() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This empties \(title). It cannot be undone.")
        }
    }

    private var cards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(viewModel.products.prefix(atMost)) { product in
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

