import Combine
import Foundation
import Bag

/// Holds the current bag and the current list of things to tell the shopper, keeps them
/// on disk together, swaps them when the owner changes, and tells anyone watching. It
/// decides nothing about what either one means.
///
/// Takes owners rather than sessions. Who is signed in is not this layer's concern; which
/// bag is the live one is.
@MainActor
public final class DefaultBagRepository: BagRepository {
    private let store: BagStore
    private let bagSubject: CurrentValueSubject<Bag, Never>
    private let changesSubject: CurrentValueSubject<BagChanges, Never>
    private var owner: BagOwner
    private var cancellables = Set<AnyCancellable>()
    private var pendingWrite: Task<Void, Never>?

    public init(
        store: BagStore,
        owner: BagOwner,
        ownerPublisher: AnyPublisher<BagOwner, Never>
    ) {
        self.store = store
        self.owner = owner

        let kept = store.getBag(for: owner)
        self.bagSubject = CurrentValueSubject(kept.bag)
        self.changesSubject = CurrentValueSubject(kept.changes)

        ownerPublisher
            .sink { [weak self] owner in
                self?.switchOwner(to: owner)
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
        let owner = owner
        let previous = pendingWrite
        pendingWrite = Task {
            await previous?.value
            await store.setBag(bag, changes: changes, for: owner)
        }
    }

    func flushPendingWrites() async {
        await pendingWrite?.value
    }

    /// Each owner's bag stays theirs. Signing in shows the shopper their own bag; signing out
    /// hands the guest bag back exactly as it was left.
    private func switchOwner(to owner: BagOwner) {
        guard owner != self.owner else { return }
        self.owner = owner
        let kept = store.getBag(for: owner)
        bagSubject.value = kept.bag
        changesSubject.value = kept.changes
    }
}
