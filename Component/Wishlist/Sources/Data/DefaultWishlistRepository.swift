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
    private var pendingWrite: Task<Void, Never>?

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

    public func save(_ wishlist: Wishlist) {
        subject.value = wishlist

        let store = store
        let owner = owner
        let items = wishlist.items
        let previous = pendingWrite
        pendingWrite = Task {
            await previous?.value
            await store.setItems(items, for: owner)
        }
    }

    func flushPendingWrites() async {
        await pendingWrite?.value
    }

    private func switchOwner(to owner: UserID?) {
        guard owner != self.owner else { return }
        self.owner = owner
        subject.value = Wishlist(items: store.getItems(for: owner))
    }
}
