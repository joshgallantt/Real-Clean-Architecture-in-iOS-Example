import Combine
import Foundation
import Wishlist

@MainActor
public final class DefaultWishlistRepository: WishlistRepository {
    private let store: WishlistStore
    private let subject: CurrentValueSubject<[WishlistItem], Never>
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
        self.subject = CurrentValueSubject(Self.newestFirst(store.getItems(forUserKey: userKey)))

        userKeyPublisher
            .sink { [weak self] key in
                self?.switchUser(to: key)
            }
            .store(in: &cancellables)
    }

    public var itemsPublisher: AnyPublisher<[WishlistItem], Never> {
        subject.eraseToAnyPublisher()
    }

    public var items: [WishlistItem] {
        subject.value
    }

    public func isInWishlistPublisher(productId: Int) -> AnyPublisher<Bool, Never> {
        subject
            .map { items in items.contains { $0.id == productId } }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public func add(productId: Int) {
        guard !subject.value.contains(where: { $0.id == productId }) else { return }
        var items = subject.value
        items.insert(WishlistItem(id: productId), at: 0)
        persist(items)
    }

    public func remove(productId: Int) {
        var items = subject.value
        items.removeAll { $0.id == productId }
        persist(items)
    }

    // Each write awaits the previous one so rapid toggles land on disk in the order
    // they were made; without the chain, unstructured tasks could reorder and
    // persist stale state.
    private func persist(_ items: [WishlistItem]) {
        subject.value = items

        let store = store
        let userKey = userKey
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
        subject.value = Self.newestFirst(store.getItems(forUserKey: key))
    }

    // `add` prepends, so live mutations already hold this order. Sorting on read
    // covers lists written before newest-first was the rule.
    private static func newestFirst(_ items: [WishlistItem]) -> [WishlistItem] {
        items.sorted { $0.dateAdded > $1.dateAdded }
    }
}
