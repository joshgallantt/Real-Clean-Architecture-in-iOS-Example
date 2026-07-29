import Combine
import Foundation
import Wishlist

/// Holds the current wishlist, keeps it on disk, swaps it when the shopper changes, and
/// tells anyone watching. It decides nothing about what a wishlist is or how one changes.
@MainActor
public final class DefaultWishlistRepository: WishlistRepository {
    private let store: WishlistStore
    private let subject: CurrentValueSubject<Wishlist, Never>
    private var userKey: String
    private var cancellables = Set<AnyCancellable>()
    private var pendingWrite: Task<Void, Never>?

    public init(
        store: WishlistStore,
        userKey: String,
        userKeyPublisher: AnyPublisher<String, Never>
    ) {
        self.store = store
        self.userKey = userKey
        self.subject = CurrentValueSubject(Wishlist(items: store.getItems(forUserKey: userKey)))

        userKeyPublisher
            .sink { [weak self] key in
                self?.switchUser(to: key)
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
        let userKey = userKey
        let items = wishlist.items
        let previous = pendingWrite
        pendingWrite = Task {
            await previous?.value
            await store.setItems(items, forUserKey: userKey)
        }
    }

    func flushPendingWrites() async {
        await pendingWrite?.value
    }

    private func switchUser(to key: String) {
        guard key != userKey else { return }
        userKey = key
        subject.value = Wishlist(items: store.getItems(forUserKey: key))
    }
}
