import Combine
import Foundation
import Bag

@MainActor
public final class DefaultBagRepository: BagRepository {
    private let store: BagStore
    private let subject: CurrentValueSubject<[BagItem], Never>
    private var userKey: String
    private var cancellables = Set<AnyCancellable>()
    private var pendingWrite: Task<Void, Never>?

    public init(
        store: BagStore,
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

    public var itemsPublisher: AnyPublisher<[BagItem], Never> {
        subject.eraseToAnyPublisher()
    }

    public var items: [BagItem] {
        subject.value
    }

    public func quantityPublisher(productId: Int) -> AnyPublisher<Int, Never> {
        subject
            .map { items in items.first { $0.id == productId }?.quantity ?? 0 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public func add(productId: Int) {
        var items = subject.value
        if let index = items.firstIndex(where: { $0.id == productId }) {
            let existing = items[index]
            items[index] = BagItem(id: existing.id, quantity: existing.quantity + 1, dateAdded: existing.dateAdded)
        } else {
            items.insert(BagItem(id: productId, quantity: 1), at: 0)
        }
        persist(items)
    }

    public func remove(productId: Int) {
        var items = subject.value
        items.removeAll { $0.id == productId }
        persist(items)
    }

    public func updateQuantity(productId: Int, quantity: Int) {
        guard quantity > 0 else {
            remove(productId: productId)
            return
        }
        var items = subject.value
        guard let index = items.firstIndex(where: { $0.id == productId }) else { return }
        let existing = items[index]
        items[index] = BagItem(id: existing.id, quantity: quantity, dateAdded: existing.dateAdded)
        persist(items)
    }

    // Each write awaits the previous one so rapid mutations land on disk in the
    // order they were made; without the chain, unstructured tasks could reorder
    // and persist stale state.
    private func persist(_ items: [BagItem]) {
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
    private static func newestFirst(_ items: [BagItem]) -> [BagItem] {
        items.sorted { $0.dateAdded > $1.dateAdded }
    }
}
