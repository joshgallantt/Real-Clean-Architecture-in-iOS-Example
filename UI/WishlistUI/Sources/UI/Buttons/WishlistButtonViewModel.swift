import Combine
import Foundation
import Wishlist
import AuthGate
import SnackbarUI

@MainActor
public final class WishlistButtonViewModel: ObservableObject {
    @Published private(set) var isInWishlist = false

    private let productId: Int
    private let addProductToWishlist: AddProductToWishlistUseCase
    private let removeProductFromWishlist: RemoveProductFromWishlistUseCase
    private let authGate: AuthGate
    private let snackbar: SnackbarPresenting
    private var cancellables = Set<AnyCancellable>()

    public init(
        productId: Int,
        productIsWishlisted: ProductIsWishlistedUseCase,
        addProductToWishlist: AddProductToWishlistUseCase,
        removeProductFromWishlist: RemoveProductFromWishlistUseCase,
        authGate: AuthGate,
        snackbar: SnackbarPresenting
    ) {
        self.productId = productId
        self.addProductToWishlist = addProductToWishlist
        self.removeProductFromWishlist = removeProductFromWishlist
        self.authGate = authGate
        self.snackbar = snackbar

        productIsWishlisted(productId: productId)
            .sink { [weak self] value in
                self?.isInWishlist = value
            }
            .store(in: &cancellables)
    }

    func didTap() {
        // Capture dependencies, not self: a queued auth action or snackbar undo must
        // not keep a discarded grid cell's view model alive.
        let add = addProductToWishlist
        let remove = removeProductFromWishlist
        let snackbar = snackbar
        let productId = productId

        if isInWishlist {
            remove(productId: productId)
            snackbar.show(Snackbar(
                title: "Removed from Wishlist",
                message: "This item is no longer saved.",
                icon: "heart.slash",
                action: .undo { add(productId: productId) }
            ))
        } else {
            // For a guest this presents the auth flow and adds once they authenticate.
            authGate.requireAuthentication {
                add(productId: productId)
                snackbar.show(Snackbar(
                    title: "Added to Wishlist",
                    message: "Find it any time in your wishlist.",
                    icon: "heart.fill",
                    action: .undo { remove(productId: productId) }
                ))
            }
        }
    }
}
