import Combine
import Foundation
import Bag
import Session

@MainActor
/// Evans, *Domain-Driven Design* (2003) — Repositories. Fowler, *PoEAA* (2002) — Repository: it
/// keeps and hands back aggregates and decides nothing about what they mean.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: takes an owner and a
/// stream of owners, never a `Session`. It needs to know whose bag is live, not to understand
/// identity.
public final class DefaultBagRepository: BagRepository {
    private let store: BagStore
    private let bagSubject: CurrentValueSubject<Bag, Never>
    private let changesSubject: CurrentValueSubject<BagChanges, Never>
    private var owner: Owner
    private var cancellables = Set<AnyCancellable>()
    private var pendingWrite: Task<Void, Never>?

    public init(
        store: BagStore,
        owner: Owner,
        ownerPublisher: AnyPublisher<Owner, Never>
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

    private func switchOwner(to owner: Owner) {
        guard owner != self.owner else { return }
        self.owner = owner
        let kept = store.getBag(for: owner)
        bagSubject.value = kept.bag
        changesSubject.value = kept.changes
    }
}
