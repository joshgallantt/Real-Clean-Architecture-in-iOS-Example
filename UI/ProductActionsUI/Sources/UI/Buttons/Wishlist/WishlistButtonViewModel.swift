import Combine
import Foundation
import Product
import Wishlist
import AuthUI
import SnackbarUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class WishlistButtonViewModel: ObservableObject {
    @Published private(set) var isInWishlist = false

    private let productId: ProductID
    private let addProductToWishlist: AddProductToWishlistUseCase
    private let removeProductFromWishlist: RemoveProductFromWishlistUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private var cancellables = Set<AnyCancellable>()
    private var inFlight: Task<Void, Never>?

    public init(
        productId: ProductID,
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

    /// Which way a tap goes is decided from `isInWishlist`, and that only becomes true once the save
    /// has been kept and published. A second tap arriving before then would read the state the first
    /// one set out to change and repeat it, so tapping on and straight off again left it on. Each tap
    /// waits for the one before it to settle, which is what makes two taps two decisions rather than
    /// the same decision twice.
    func didTap() {
        let previous = inFlight
        inFlight = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            if self.isInWishlist {
                await self.remove()
            } else {
                await self.add()
            }
        }
    }

    private func add() async {
        let add = addProductToWishlist
        let snackbarPresenter = snackbarPresenter
        let productId = productId

        switch await add(productId: productId) {
        case .success:
            snackbarPresenter.show(Snackbar(
                title: "Saved",
                message: "It's in your faves.",
                icon: "heart.fill"
            ))
        case .failure(.unauthenticated):
            guard await authPresenter.show(AuthenticationPrompt(
                title: "Keep Your Faves",
                message: "Sign in and everything you save sticks around.",
                icon: "heart.fill"
            )) else {
                return
            }
            await self.add()
        case .failure(.unavailable):
            snackbarPresenter.show(Snackbar(
                title: "Didn't Save",
                message: "That didn't stick. Try again?",
                icon: "heart.slash",
                action: .retry { Task { await self.add() } }
            ))
        }
    }

    private func remove() async {
        let remove = removeProductFromWishlist
        let snackbarPresenter = snackbarPresenter
        let productId = productId

        switch await remove(productId: productId) {
        case .success:
            snackbarPresenter.show(Snackbar(
                title: "Unsaved",
                message: "Gone from your faves.",
                icon: "heart.slash"
            ))
        case .failure(.unauthenticated):
            guard await authPresenter.show(AuthenticationPrompt(
                title: "Your Faves",
                message: "Sign in to change what you've saved.",
                icon: "heart.slash"
            )) else {
                return
            }
            await self.remove()
        case .failure(.unavailable):
            snackbarPresenter.show(Snackbar(
                title: "Didn't Change",
                message: "That didn't stick. Try again?",
                icon: "heart.slash",
                action: .retry { Task { await self.remove() } }
            ))
        }
    }
}
