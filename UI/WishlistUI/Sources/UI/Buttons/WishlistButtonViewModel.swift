import Combine
import Foundation
import SwiftUI
import Wishlist
import LoginUI
import SnackbarUI

@MainActor
public final class WishlistButtonViewModel: ObservableObject {
    @Published private(set) var isInWishlist = false

    private let productId: Int
    private let addProductToWishlist: AddProductToWishlistUseCase
    private let removeProductFromWishlist: RemoveProductFromWishlistUseCase
    private let authPresenting: AuthSheetCoordinator
    private let authGate: (@escaping () -> Void, @escaping () -> Void) -> AnyView
    private let snackbar: SnackbarPresenting
    private var cancellables = Set<AnyCancellable>()

    public init(
        productId: Int,
        productIsWishlisted: ProductIsWishlistedUseCase,
        addProductToWishlist: AddProductToWishlistUseCase,
        removeProductFromWishlist: RemoveProductFromWishlistUseCase,
        authPresenting: AuthSheetCoordinator,
        authGate: @escaping (@escaping () -> Void, @escaping () -> Void) -> AnyView,
        snackbar: SnackbarPresenting
    ) {
        self.productId = productId
        self.addProductToWishlist = addProductToWishlist
        self.removeProductFromWishlist = removeProductFromWishlist
        self.authPresenting = authPresenting
        self.authGate = authGate
        self.snackbar = snackbar

        productIsWishlisted(productId: productId)
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
        let snackbar = snackbar
        let productId = productId

        switch await add(productId: productId) {
        case .success:
            snackbar.show(Snackbar(
                title: "Added to Wishlist",
                message: "Find it any time in your wishlist.",
                icon: "heart.fill",
                action: .undo { Task { await remove(productId: productId) } }
            ))
        case .failure(.unauthenticated):
            guard await authPresenting.requireAuthentication(gate: authGate) else { return }
            await self.add()
        case .failure(.network):
            snackbar.show(Snackbar(
                title: "Couldn't Add to Wishlist",
                message: "Check your connection and try again.",
                icon: "wifi.slash",
                action: .retry { [weak self] in Task { await self?.add() } }
            ))
        }
    }

    private func remove() async {
        let add = addProductToWishlist
        let remove = removeProductFromWishlist
        let snackbar = snackbar
        let productId = productId

        switch await remove(productId: productId) {
        case .success:
            snackbar.show(Snackbar(
                title: "Removed from Wishlist",
                message: "This item is no longer saved.",
                icon: "heart.slash",
                action: .undo { Task { await add(productId: productId) } }
            ))
        case .failure(.unauthenticated):
            guard await authPresenting.requireAuthentication(gate: authGate) else { return }
            await self.remove()
        case .failure(.network):
            snackbar.show(Snackbar(
                title: "Couldn't Remove Item",
                message: "Check your connection and try again.",
                icon: "wifi.slash",
                action: .retry { [weak self] in Task { await self?.remove() } }
            ))
        }
    }
}
