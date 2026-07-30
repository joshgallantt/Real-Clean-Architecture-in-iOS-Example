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
    }
}
