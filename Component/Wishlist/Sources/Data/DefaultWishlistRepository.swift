import Combine
import Foundation
import Wishlist

@MainActor
public final class DefaultWishlistRepository: WishlistRepository {
    private let store: WishlistStore
    private let subject: CurrentValueSubject<[WishlistItem], Never>
    private var userKey: String
    private var cancellables = Set<AnyCancellable>()

    public init(
        store: WishlistStore,
        userKey: String,
        userKeyPublisher: AnyPublisher<String, Never>
    ) {
        self.store = store
        self.userKey = userKey
        self.subject = CurrentValueSubject(store.getItems(forUserKey: userKey))

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
        items.append(WishlistItem(id: productId))
        persist(items)
    }

    public func remove(productId: Int) {
        var items = subject.value
        items.removeAll { $0.id == productId }
        persist(items)
    }

    private func persist(_ items: [WishlistItem]) {
        subject.value = items
        store.setItems(items, forUserKey: userKey)
    }

    private func switchUser(to key: String) {
        guard key != userKey else { return }
        userKey = key
        subject.value = store.getItems(forUserKey: key)
    }
}
