import Combine
import Foundation
import Wishlist
import AuthUI
import SnackbarUI

@MainActor
public final class WishlistButtonViewModel: ObservableObject {
    @Published private(set) var isInWishlist = false

    private let productId: Int
    private let addProductToWishlist: AddProductToWishlistUseCase
    private let removeProductFromWishlist: RemoveProductFromWishlistUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private var cancellables = Set<AnyCancellable>()

    public init(
        productId: Int,
        observeProductIsWishlisted: ObserveProductIsWishlistedUseCase,
        addProductToWishlist: AddProductToWishlistUseCase,
        removeProductFromWishlist: RemoveProductFromWishlistUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting
    ) {
        self.productId = productId
        self.addProductToWishlist = addProductToWishlist
        self.removeProductFromWishlist = removeProductFromWishlist
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter

        observeProductIsWishlisted(productId: productId)
            .sink { [weak self] value in
                self?.isInWishlist = value
            }
            .store(in: &cancellables)
    }

    func didTap() {
        Task { [weak self] in
            guard let self else { return }
            if self.isInWishlist {
                await self.remove()
            } else {
                await self.add()
            }
        }
    }

    // Capture dependencies, not self: the snackbar undo closures escape this call
    // and must not keep a discarded grid cell's view model alive.

    private func add() async {
        let add = addProductToWishlist
        let remove = removeProductFromWishlist
        let snackbarPresenter = snackbarPresenter
        let productId = productId

        switch await add(productId: productId) {
        case .success:
            snackbarPresenter.show(Snackbar(
                title: "Added to Wishlist",
                message: "Find it any time in your wishlist.",
                icon: "heart.fill",
                action: .undo { Task { await remove(productId: productId) } }
            ))
        case .failure(.unauthenticated):
            guard await authPresenter.show(AuthenticationPrompt(
                title: "Save to Your Wishlist",
                message: "Log in or create an account to build your wishlist.",
                icon: "heart.fill"
            )) else {
                return
            }
            await self.add()
        }
    }

    private func remove() async {
        let add = addProductToWishlist
        let remove = removeProductFromWishlist
        let snackbarPresenter = snackbarPresenter
        let productId = productId

        switch await remove(productId: productId) {
        case .success:
            snackbarPresenter.show(Snackbar(
                title: "Removed from Wishlist",
                message: "This item is no longer saved.",
                icon: "heart.slash",
                action: .undo { Task { await add(productId: productId) } }
            ))
        case .failure(.unauthenticated):
            guard await authPresenter.show(AuthenticationPrompt(
                title: "Update Your Wishlist",
                message: "Log in or create an account to manage your wishlist.",
                icon: "heart.slash"
            )) else {
                return
            }
            await self.remove()
        }
    }
}
