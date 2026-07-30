import Combine
import Foundation
import Wishlist
import WishlistData
import Session

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: wiring, and nothing else. It
/// is the only thing that knows the concrete types, so it is the only thing that has to change when
/// one is swapped. Not unit tested — there is no behaviour here to test.
///
/// Fowler, *Inversion of Control Containers and the Dependency Injection Pattern* (2004) —
/// Dependency Injection.
public struct WishlistDI {
    private let repository: WishlistRepository

    public let observeWishlistUseCase: ObserveWishlistUseCase
    public let observeProductIsWishlistedUseCase: ObserveProductIsWishlistedUseCase
    public let addProductToWishlistUseCase: AddProductToWishlistUseCase
    public let removeProductFromWishlistUseCase: RemoveProductFromWishlistUseCase

    @MainActor
    public init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        store: WishlistStore = FileWishlistStore()
    ) {
        /// Evans, *Domain-Driven Design* (2003) — Bounded Context: turning a session into an owner
        /// happens here, once.
        let repository = DefaultWishlistRepository(
            store: store,
            owner: Self.owner(for: getSession()),
            ownerPublisher: observeSession()
                .map(Self.owner(for:))
                .removeDuplicates()
                .eraseToAnyPublisher()
        )
        self.repository = repository

        self.observeWishlistUseCase = DefaultObserveWishlistUseCase(repository: repository)
        self.observeProductIsWishlistedUseCase = DefaultObserveProductIsWishlistedUseCase(repository: repository)
        self.addProductToWishlistUseCase = DefaultAddProductToWishlistUseCase(
            repository: repository,
            getSession: getSession
        )
        self.removeProductFromWishlistUseCase = DefaultRemoveProductFromWishlistUseCase(
            repository: repository,
            getSession: getSession
        )
    }

    /// Evans, *Domain-Driven Design* (2003) — Assertions: exhaustive over `Session`, so a new kind
    /// of session has to be a decision about whose wishlist is live. `nil` is the absence of a
    /// list, not a guest with an empty one — a guest cannot save anything, so there is nothing to
    /// own.
    private static func owner(for session: Session) -> UserID? {
        switch session {
        case .guest:
            nil
        case .authenticated(let user):
            user.id
        }
    }
}
