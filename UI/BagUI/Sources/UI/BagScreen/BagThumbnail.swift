import SwiftUI
import Kingfisher
import Product

/// The picture on a row, or the shape of one until the shop has said what the row is.
struct BagThumbnail: View {
    let product: Product?

    var body: some View {
        if let product {
            KFImage(URL(string: product.thumbnail))
                .resizable()
                .placeholder { ProgressView() }
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(width: 56, height: 56)
        }
    }
}
