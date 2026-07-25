import SwiftUI
import Wishlist
import AuthGate

@MainActor
public struct WishlistButtonView: View {
    @State private var isInWishlist = false

    private let productId: Int
    private let productIsWishlisted: ProductIsWishlistedUseCase
    private let addProductToWishlist: AddProductToWishlistUseCase
    private let removeProductFromWishlist: RemoveProductFromWishlistUseCase
    private let authGate: AuthGate

    public init(
        productId: Int,
        productIsWishlisted: ProductIsWishlistedUseCase,
        addProductToWishlist: AddProductToWishlistUseCase,
        removeProductFromWishlist: RemoveProductFromWishlistUseCase,
        authGate: AuthGate
    ) {
        self.productId = productId
        self.productIsWishlisted = productIsWishlisted
        self.addProductToWishlist = addProductToWishlist
        self.removeProductFromWishlist = removeProductFromWishlist
        self.authGate = authGate
    }

    public var body: some View {
        Button(action: didTap) {
            Image(systemName: isInWishlist ? "heart.fill" : "heart")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isInWishlist ? .red : .primary)
                .symbolEffect(.bounce, value: isInWishlist)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .onReceive(productIsWishlisted(productId: productId).receive(on: DispatchQueue.main)) { value in
            isInWishlist = value
        }
    }

    private func didTap() {
        if isInWishlist {
            removeProductFromWishlist(productId: productId)
        } else {
            // For a guest this presents the auth flow and adds once they authenticate.
            authGate.requireAuthentication { addProductToWishlist(productId: productId) }
        }
    }
}
