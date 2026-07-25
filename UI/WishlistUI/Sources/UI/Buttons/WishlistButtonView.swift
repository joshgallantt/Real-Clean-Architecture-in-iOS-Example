import SwiftUI
import Wishlist

@MainActor
public struct WishlistButtonView: View {
    @State private var isInWishlist = false
    @State private var bounce = false

    private let productId: Int
    private let isInWishlistUseCase: IsInWishlistUseCase
    private let addToWishlistUseCase: AddToWishlistUseCase
    private let removeFromWishlistUseCase: RemoveFromWishlistUseCase

    public init(
        productId: Int,
        isInWishlistUseCase: IsInWishlistUseCase,
        addToWishlistUseCase: AddToWishlistUseCase,
        removeFromWishlistUseCase: RemoveFromWishlistUseCase
    ) {
        self.productId = productId
        self.isInWishlistUseCase = isInWishlistUseCase
        self.addToWishlistUseCase = addToWishlistUseCase
        self.removeFromWishlistUseCase = removeFromWishlistUseCase
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
            isInWishlistUseCase
                .execute(productId: productId)
                .receive(on: DispatchQueue.main)
        ) { value in
            isInWishlist = value
        }
    }

    private func toggle() {
        bounce.toggle()
        if isInWishlist {
            removeFromWishlistUseCase.execute(productId: productId)
        } else {
            addToWishlistUseCase.execute(productId: productId)
        }
    }
}
