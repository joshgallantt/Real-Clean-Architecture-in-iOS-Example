import Combine
import Foundation
import Wishlist
import AuthGate

@MainActor
public final class WishlistButtonViewModel: ObservableObject {
    @Published private(set) var isInWishlist = false

    private let productId: Int
    private let addProductToWishlist: AddProductToWishlistUseCase
    private let removeProductFromWishlist: RemoveProductFromWishlistUseCase
    private let authGate: AuthGate
    private var cancellables = Set<AnyCancellable>()

    public init(
        productId: Int,
        productIsWishlisted: ProductIsWishlistedUseCase,
        addProductToWishlist: AddProductToWishlistUseCase,
        removeProductFromWishlist: RemoveProductFromWishlistUseCase,
        authGate: AuthGate
    ) {
        self.productId = productId
        self.addProductToWishlist = addProductToWishlist
        self.removeProductFromWishlist = removeProductFromWishlist
        self.authGate = authGate

        productIsWishlisted(productId: productId)
            .sink { [weak self] value in
                self?.isInWishlist = value
            }
            .store(in: &cancellables)
    }

    func didTap() {
        if isInWishlist {
            removeProductFromWishlist(productId: productId)
        } else {
            // For a guest this presents the auth flow and adds once they authenticate.
            authGate.requireAuthentication { [addProductToWishlist, productId] in
                addProductToWishlist(productId: productId)
            }
        }
    }
}
