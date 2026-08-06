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
///
/// One use case with a state, rather than one for saving and another for unsaving. Two use cases
/// meant this had to read its own `isInWishlist` to decide which to call — a toggle re-derived from
/// the thing it was toggling.
public final class WishlistButtonViewModel: ObservableObject {
    @Published private(set) var isInWishlist = false

    private let productId: ProductID
    private let setProductIsWishlisted: SetProductIsWishlistedUseCase
    private let authPresenter: AuthPresenting
    private let snackbarPresenter: SnackbarPresenting
    private var cancellables = Set<AnyCancellable>()
    private var inFlight: Task<Void, Never>?

    public init(
        productId: ProductID,
        observeProductIsWishlisted: ObserveProductIsWishlistedUseCase,
        setProductIsWishlisted: SetProductIsWishlistedUseCase,
        authPresenter: AuthPresenting,
        snackbarPresenter: SnackbarPresenting
    ) {
        self.productId = productId
        self.setProductIsWishlisted = setProductIsWishlisted
        self.authPresenter = authPresenter
        self.snackbarPresenter = snackbarPresenter

        observeProductIsWishlisted(productId: productId)
            .sink { [weak self] value in
                self?.isInWishlist = value
            }
            .store(in: &cancellables)
    }

    /// Which way a tap goes is read from `isInWishlist`, and that only changes once the save has
    /// been kept and published. Deciding at the moment of the tap meant a second tap read the state
    /// the first one had set out to change, so tapping on and straight off again left it on. The
    /// decision is made inside the queued work instead, once the tap before it has settled.
    func didTap() {
        enqueue { [weak self] in
            guard let self else { return }
            await self.apply(isWishlisted: !self.isInWishlist)
        }
    }

    /// One tap at a time, in the order the shopper made them, so two taps are two decisions rather
    /// than the same decision twice.
    private func enqueue(_ work: @escaping @MainActor () async -> Void) {
        let previous = inFlight
        inFlight = Task {
            await previous?.value
            await work()
        }
    }

    private func apply(isWishlisted: Bool) async {
        switch await setProductIsWishlisted(productId: productId, isWishlisted: isWishlisted) {
        case .success:
            snackbarPresenter.show(told(isWishlisted))

        case .failure(.unauthenticated):
            guard await authPresenter.show(prompt(isWishlisted)) else { return }
            await apply(isWishlisted: isWishlisted)

        case .failure(.unavailable):
            snackbarPresenter.show(Snackbar(
                title: isWishlisted ? "Didn't Save" : "Didn't Change",
                message: "That didn't stick. Try again?",
                icon: "heart.slash",
                action: .retry { Task { await self.apply(isWishlisted: isWishlisted) } }
            ))
        }
    }

    private func told(_ isWishlisted: Bool) -> Snackbar {
        isWishlisted
            ? Snackbar(
                title: "Saved",
                message: "It's in your faves.",
                icon: "heart.fill"
            )
            : Snackbar(
                title: "Unsaved",
                message: "Gone from your faves.",
                icon: "heart.slash"
            )
    }

    private func prompt(_ isWishlisted: Bool) -> AuthenticationPrompt {
        isWishlisted
            ? AuthenticationPrompt(
                title: "Keep Your Faves",
                message: "Sign in and everything you save sticks around.",
                icon: "heart.fill"
            )
            : AuthenticationPrompt(
                title: "Your Faves",
                message: "Sign in to change what you've saved.",
                icon: "heart.slash"
            )
    }
}
