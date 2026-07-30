import Combine
import Foundation
import Wishlist
import WishlistData
import Session

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
        // A wishlist belongs to a signed-in shopper, so who owns one is a `UserID` or
        // nobody at all. Turning a session into that happens here once.
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

    /// Exhaustive over `Session` rather than reading `session.user`, so a new kind of session
    /// has to be a decision about whose wishlist is live instead of quietly becoming nobody's.
    ///
    /// `nil` is not a guest with an empty list — it is the absence of a list. A guest cannot
    /// save anything, so there is nothing for one to own.
    private static func owner(for session: Session) -> UserID? {
        switch session {
        case .guest:
            nil
        case .authenticated(let user):
            user.id
        }
    }
}
