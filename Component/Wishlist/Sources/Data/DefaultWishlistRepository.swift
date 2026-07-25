import Combine
import Foundation
import Wishlist
import Session

@MainActor
public final class DefaultWishlistRepository: WishlistRepository {
    private let store: WishlistStore
    private let subject: CurrentValueSubject<[WishlistItem], Never>
    private var userKey: String
    private var cancellables = Set<AnyCancellable>()

    public init(
        store: WishlistStore,
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase
    ) {
        self.store = store
        let key = Self.userKey(for: getSession.execute())
        self.userKey = key
        self.subject = CurrentValueSubject(store.getItems(forUserKey: key))

        observeSession.execute()
            .sink { [weak self] session in
                self?.switchUser(to: Self.userKey(for: session))
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

    private static func userKey(for session: Session) -> String {
        session.user.map { String($0.id) } ?? "guest"
    }
}
