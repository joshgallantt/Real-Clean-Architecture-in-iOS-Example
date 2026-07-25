import SwiftUI
import Product

public struct ProductCardView: View {
    private let product: Product
    private let accessory: () -> AnyView

    public init(
        product: Product,
        accessory: @escaping () -> AnyView = { AnyView(EmptyView()) }
    ) {
        self.product = product
        self.accessory = accessory
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .overlay {
                    AsyncImage(url: URL(string: product.thumbnail)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topTrailing) {
                    accessory()
                        .padding(8)
                }

            Text(product.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            Text(product.brand)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(product.price, format: .currency(code: "USD"))
                .font(.subheadline)
        }
    }
}
