import Combine
import Foundation
import Session
import Waitlist

@MainActor
/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Repositories. Fowler, *PoEAA* (2002), Ch. 13 —
/// Repository: it keeps and hands back aggregates and decides nothing about what they mean.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: takes an owner and a
/// stream of owners, never a `Session`. It needs to know whose waitlist is live, not to understand
/// identity — the same shape the bag's, the wishlist's and the history's take.
public final class DefaultWaitlistRepository: WaitlistRepository {
    private let store: WaitlistStore
    private let subject: CurrentValueSubject<Waitlist, Never>
    private var owner: UserID?
    private var cancellables = Set<AnyCancellable>()

    public init(
        store: WaitlistStore,
        owner: UserID?,
        ownerPublisher: AnyPublisher<UserID?, Never>
    ) {
        self.store = store
        self.owner = owner
        self.subject = CurrentValueSubject(Waitlist(items: store.getItems(for: owner)))

        ownerPublisher
            .sink { [weak self] owner in
                self?.switchOwner(to: owner)
            }
            .store(in: &cancellables)
    }

    public var waitlist: Waitlist {
        subject.value
    }

    public var waitlistPublisher: AnyPublisher<Waitlist, Never> {
        subject.eraseToAnyPublisher()
    }

    /// Fowler, *PoEAA* (2002), Ch. 13 — Repository: kept first, published second. A bell that lit
    /// up before the list was written down would be a promise nothing had recorded.
    public func save(_ waitlist: Waitlist) async throws {
        try await store.setItems(waitlist.items, for: owner)
        subject.value = waitlist
    }

    private func switchOwner(to owner: UserID?) {
        guard owner != self.owner else { return }
        self.owner = owner
        subject.value = Waitlist(items: store.getItems(for: owner))
    }
}
