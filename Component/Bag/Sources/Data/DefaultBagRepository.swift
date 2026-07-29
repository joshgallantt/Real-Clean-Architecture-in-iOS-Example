import Combine
import Foundation
import Bag

/// Holds the current bag and the current list of things to tell the shopper, keeps them
/// on disk together, swaps them when the shopper changes, and tells anyone watching. It
/// decides nothing about what either one means.
@MainActor
public final class DefaultBagRepository: BagRepository {
    private let store: BagStore
    private let bagSubject: CurrentValueSubject<Bag, Never>
    private let changesSubject: CurrentValueSubject<BagChanges, Never>
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

        let kept = store.getBag(forUserKey: userKey)
        self.bagSubject = CurrentValueSubject(kept.bag)
        self.changesSubject = CurrentValueSubject(kept.changes)

        userKeyPublisher
            .sink { [weak self] key in
                self?.switchUser(to: key)
            }
            .store(in: &cancellables)
    }

    public var bag: Bag { bagSubject.value }

    public var bagPublisher: AnyPublisher<Bag, Never> { bagSubject.eraseToAnyPublisher() }

    public var changes: BagChanges { changesSubject.value }

    public var changesPublisher: AnyPublisher<BagChanges, Never> { changesSubject.eraseToAnyPublisher() }

    // Each write awaits the previous one so rapid changes land on disk in the order they
    // were made; without the chain, unstructured tasks could reorder and persist stale
    // state.
    public func save(bag: Bag, changes: BagChanges) {
        bagSubject.value = bag
        changesSubject.value = changes

        let store = store
        let userKey = userKey
        let previous = pendingWrite
        pendingWrite = Task {
            await previous?.value
            await store.setBag(bag, changes: changes, forUserKey: userKey)
        }
    }

    func flushPendingWrites() async {
        await pendingWrite?.value
    }

    private func switchUser(to key: String) {
        guard key != userKey else { return }
        userKey = key
        let kept = store.getBag(forUserKey: key)
        bagSubject.value = kept.bag
        changesSubject.value = kept.changes
    }
}
