import Combine
import Foundation
import Session
import Wishlist

/// Holds the current wishlist, keeps it on disk, swaps it when the owner changes, and
/// tells anyone watching. It decides nothing about what a wishlist is or how one changes.
///
/// Takes owners rather than sessions. Who is signed in is not this layer's concern; whose
/// list is the live one is.
@MainActor
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

    // Each write awaits the previous one so rapid toggles land on disk in the order they
    // were made; without the chain, unstructured tasks could reorder and persist stale
    // state.
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
