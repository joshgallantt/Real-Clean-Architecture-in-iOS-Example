import Combine
import Foundation
import Bag
import Session

@MainActor
/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Repositories. Fowler, *PoEAA* (2002), Ch. 13 —
/// Repository: it keeps and hands back the aggregate and decides nothing about what it means.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: takes a session and a
/// stream of sessions, and reads only who is signed in. It needs to know whose bag is
/// live, not to understand identity — so it compares ids, and a changed profile is not a
/// changed owner.
public final class DefaultBagRepository: BagRepository {
    private let store: BagStore
    private let bagSubject: CurrentValueSubject<Bag, Never>
    private var session: Session
    private var cancellables = Set<AnyCancellable>()
    private var pendingWrite: Task<Void, Never>?

    public init(
        store: BagStore,
        session: Session,
        sessionPublisher: AnyPublisher<Session, Never>
    ) {
        self.store = store
        self.session = session

        self.bagSubject = CurrentValueSubject(store.getBag(for: session))

        sessionPublisher
            .sink { [weak self] session in
                self?.switchSession(to: session)
            }
            .store(in: &cancellables)
    }

    public var bag: Bag { bagSubject.value }

    public var bagPublisher: AnyPublisher<Bag, Never> { bagSubject.eraseToAnyPublisher() }

    public func save(_ bag: Bag) {
        bagSubject.value = bag

        let store = store
        let session = session
        let previous = pendingWrite
        pendingWrite = Task {
            await previous?.value
            await store.setBag(bag, for: session)
        }
    }

    private func switchSession(to session: Session) {
        guard session.user?.id != self.session.user?.id else { return }
        self.session = session
        bagSubject.value = store.getBag(for: session)
    }
}
