import Combine
import Foundation
import Session
import Wishlist

@MainActor
/// Evans, *Domain-Driven Design* (2003) — Repositories. Fowler, *PoEAA* (2002) — Repository: it
/// keeps and hands back aggregates and decides nothing about what they mean.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: takes an owner and a
/// stream of owners, never a `Session`. It needs to know whose list is live, not to understand
/// identity.
public final class DefaultWishlistRepository: WishlistRepository {
    private let store: WishlistStore
    private let subject: CurrentValueSubject<Wishlist, Never>
    private var owner: UserID?
    private var cancellables = Set<AnyCancellable>()

    public init(
        store: WishlistStore,
        owner: UserID?,
        ownerPublisher: AnyPublisher<UserID?, Never>
    ) {
        self.store = store
        self.owner = owner
        self.subject = CurrentValueSubject(Wishlist(items: store.getItems(for: owner)))

        ownerPublisher
            .sink { [weak self] owner in
                self?.switchOwner(to: owner)
            }
            .store(in: &cancellables)
    }

    public var wishlist: Wishlist {
        subject.value
    }

    public var wishlistPublisher: AnyPublisher<Wishlist, Never> {
        subject.eraseToAnyPublisher()
    }

    /// Fowler, *PoEAA* (2002) — Repository: kept first, published second. Publishing optimistically
    /// and writing behind it would show the shopper a list that does not exist anywhere, and there
    /// would be no honest moment to take it back. Awaiting the write also serialises saves without
    /// a queue of pending ones to sequence by hand.
    public func save(_ wishlist: Wishlist) async throws {
        try await store.setItems(wishlist.items, for: owner)
        subject.value = wishlist
    }

    private func switchOwner(to owner: UserID?) {
        guard owner != self.owner else { return }
        self.owner = owner
        subject.value = Wishlist(items: store.getItems(for: owner))
    }
}
