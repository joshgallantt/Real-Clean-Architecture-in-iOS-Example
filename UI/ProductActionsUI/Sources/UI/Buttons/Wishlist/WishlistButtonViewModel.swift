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

    private func add() async {
        let add = addProductToWishlist
        let remove = removeProductFromWishlist
        let snackbarPresenter = snackbarPresenter
        let productId = productId

        switch await add(productId: productId) {
        case .success:
            snackbarPresenter.show(Snackbar(
                title: "Saved",
                message: "It's in your faves.",
                icon: "heart.fill",
                action: undo(
                    by: { await remove(productId: productId) },
                    sayingSoIfItCannot: snackbarPresenter
                )
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
        let add = addProductToWishlist
        let remove = removeProductFromWishlist
        let snackbarPresenter = snackbarPresenter
        let productId = productId

        switch await remove(productId: productId) {
        case .success:
            snackbarPresenter.show(Snackbar(
                title: "Unsaved",
                message: "Gone from your faves.",
                icon: "heart.slash",
                action: undo(
                    by: { await add(productId: productId) },
                    sayingSoIfItCannot: snackbarPresenter
                )
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

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: an undo that could
/// not happen has to say so. A shopper whose sign-in ended between saving something and changing
/// their mind would otherwise watch the snackbar disappear as though it worked.
///
/// It cannot ask for a sign-in and resume the way the button does, because it outlives the button:
/// a wishlist heart in a lazily-rendered grid cell is gone the moment the shopper scrolls, so this
/// closure holds the use cases and the presenter rather than a view model. The most it can honestly
/// do is not claim a change that did not happen.
@MainActor
private func undo(
    by change: @escaping @MainActor () async -> Result<Void, WishlistError>,
    sayingSoIfItCannot snackbarPresenter: SnackbarPresenting
) -> SnackbarAction {
    .undo {
        Task {
            switch await change() {
            case .success:
                break
            case .failure(.unauthenticated):
                snackbarPresenter.show(Snackbar(
                    title: "Couldn't Undo That",
                    message: "Sign in to change what you've saved.",
                    icon: "heart.slash"
                ))
            case .failure(.unavailable):
                snackbarPresenter.show(Snackbar(
                    title: "Couldn't Undo That",
                    message: "That didn't stick. Try again?",
                    icon: "heart.slash",
                    action: .retry(undoAgain(change, sayingSoIfItCannot: snackbarPresenter))
                ))
            }
        }
    }
}

/// The retry on a failed undo is the same undo again, so it is built the same way — otherwise a
/// second failure would be the one that goes quiet.
@MainActor
private func undoAgain(
    _ change: @escaping @MainActor () async -> Result<Void, WishlistError>,
    sayingSoIfItCannot snackbarPresenter: SnackbarPresenting
) -> @MainActor () -> Void {
    { undo(by: change, sayingSoIfItCannot: snackbarPresenter).handler() }
}
