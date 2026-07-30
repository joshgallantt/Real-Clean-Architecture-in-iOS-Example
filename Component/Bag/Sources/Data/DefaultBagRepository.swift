import Combine
import Foundation
import Bag
import Session

@MainActor
/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Repositories. Fowler, *PoEAA* (2002), Ch. 13 —
/// Repository: it keeps and hands back aggregates and decides nothing about what they mean.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: takes an owner and a
/// stream of owners, never a `Session`. It needs to know whose bag is live, not to understand
/// identity.
public final class DefaultBagRepository: BagRepository {
    private let store: BagStore
    private let bagSubject: CurrentValueSubject<Bag, Never>
    private let noticesSubject: CurrentValueSubject<Notices, Never>
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
        self.noticesSubject = CurrentValueSubject(kept.notices)

        ownerPublisher
            .sink { [weak self] owner in
                self?.switchOwner(to: owner)
            }
            .store(in: &cancellables)
    }

    public var bag: Bag { bagSubject.value }

    public var bagPublisher: AnyPublisher<Bag, Never> { bagSubject.eraseToAnyPublisher() }

    public var notices: Notices { noticesSubject.value }

    public var noticesPublisher: AnyPublisher<Notices, Never> { noticesSubject.eraseToAnyPublisher() }

    public func save(bag: Bag, notices: Notices) {
        bagSubject.value = bag
        noticesSubject.value = notices

        let store = store
        let owner = owner
        let previous = pendingWrite
        pendingWrite = Task {
            await previous?.value
            await store.setBag(bag, notices: notices, for: owner)
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
        noticesSubject.value = kept.notices
    }
}
