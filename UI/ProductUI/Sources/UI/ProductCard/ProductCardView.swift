import SwiftUI
import Product
import Kingfisher

public struct ProductCardView: View {
    private let product: Product
    private let accessory: () -> AnyView
    private let leadingAccessory: () -> AnyView

    public init(
        product: Product,
        accessory: @escaping () -> AnyView = { AnyView(EmptyView()) },
        leadingAccessory: @escaping () -> AnyView = { AnyView(EmptyView()) }
    ) {
        self.product = product
        self.accessory = accessory
        self.leadingAccessory = leadingAccessory
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .overlay {
                    KFImage(URL(string: product.thumbnail))
                        .resizable()
                        .placeholder { ProgressView() }
                        .aspectRatio(contentMode: .fill)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topTrailing) {
                    accessory()
                        .padding(8)
                }
                .overlay(alignment: .topLeading) {
                    leadingAccessory()
                        .padding(8)
                }

            Text(product.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            Text(product.brand)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(product.price.formatted())
                .font(.subheadline)
        }
        /// A card is exactly as tall as its own contents, and refuses to be squeezed into whatever
        /// height it is offered.
        ///
        /// Without this the picture pays for the words. It is the only part with no height of its
        /// own — `fit` reads the width *and* the height on offer and takes the largest box
        /// satisfying both — so in a row that hands every card the height of the tallest, a
        /// two-line name came out of the photograph, and the products with most to say were shown
        /// smallest.
        ///
        /// It goes here rather than on the picture. Fixing the picture alone leaves it with no
        /// height to reason from and the words are squeezed instead, which truncates a two-line
        /// name to one. Fixing the card settles the width, and the width settles everything else:
        /// the picture is identical on every card, and a longer name simply makes its own card
        /// taller. Whatever arranges them aligns them at the top.
        .fixedSize(horizontal: false, vertical: true)
    }
}
