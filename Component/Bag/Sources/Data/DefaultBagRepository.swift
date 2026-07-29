import Combine
import Foundation
import Bag

/// Holds the current bag, keeps it on disk, swaps it when the shopper changes, and
/// tells anyone watching. It decides nothing about what a bag is or how one changes.
@MainActor
public final class DefaultBagRepository: BagRepository {
    private let store: BagStore
    private let subject: CurrentValueSubject<Bag, Never>
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
        self.subject = CurrentValueSubject(store.getBag(forUserKey: userKey))

        userKeyPublisher
            .sink { [weak self] key in
                self?.switchUser(to: key)
            }
            .store(in: &cancellables)
    }

    public var bag: Bag {
        subject.value
    }

    public var bagPublisher: AnyPublisher<Bag, Never> {
        subject.eraseToAnyPublisher()
    }

    // Each write awaits the previous one so rapid changes land on disk in the order
    // they were made; without the chain, unstructured tasks could reorder and persist
    // stale state.
    public func save(_ bag: Bag) {
        subject.value = bag

        let store = store
        let userKey = userKey
        let previous = pendingWrite
        pendingWrite = Task {
            await previous?.value
            await store.setBag(bag, forUserKey: userKey)
        }
    }

    func flushPendingWrites() async {
        await pendingWrite?.value
    }

    private func switchUser(to key: String) {
        guard key != userKey else { return }
        userKey = key
        subject.value = store.getBag(forUserKey: key)
    }
}
