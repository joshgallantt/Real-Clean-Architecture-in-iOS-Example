import SwiftUI
import Wishlist

@MainActor
public struct WishlistButtonView: View {
    @State private var isInWishlist = false
    @State private var bounce = false

    private let productId: Int
    private let productIsWishlisted: ProductIsWishlistedUseCase
    private let addProductToWishlist: AddProductToWishlistUseCase
    private let removeProductFromWishlist: RemoveProductFromWishlistUseCase

    public init(
        productId: Int,
        productIsWishlisted: ProductIsWishlistedUseCase,
        addProductToWishlist: AddProductToWishlistUseCase,
        removeProductFromWishlist: RemoveProductFromWishlistUseCase
    ) {
        self.productId = productId
        self.productIsWishlisted = productIsWishlisted
        self.addProductToWishlist = addProductToWishlist
        self.removeProductFromWishlist = removeProductFromWishlist
    }

    public var body: some View {
        Button(action: toggle) {
            Image(systemName: isInWishlist ? "heart.fill" : "heart")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isInWishlist ? .red : .primary)
                .symbolEffect(.bounce, value: bounce)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .onReceive(
            productIsWishlisted(productId: productId)
                .receive(on: DispatchQueue.main)
        ) { value in
            isInWishlist = value
        }
    }

    private func toggle() {
        bounce.toggle()
        if isInWishlist {
            removeProductFromWishlist(productId: productId)
        } else {
            addProductToWishlist(productId: productId)
        }
    }
}
