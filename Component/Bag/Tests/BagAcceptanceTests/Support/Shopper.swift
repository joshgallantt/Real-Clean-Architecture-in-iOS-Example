import Combine
import Foundation
import Bag
import BagData
import BagDI
import Session

/// The bag feature wired as the composition root wires it, over an in-memory store.
/// Tests drive it only through the use cases the UI is given — nothing reaches past
/// this into the repository or the store.
@MainActor
final class Shopper {
    let store: InMemoryBagStore

    private let sessions: CurrentValueSubject<Session, Never>
    private let di: BagDI
    private var cancellables = Set<AnyCancellable>()
    private(set) var bag = Bag()

    init(store: InMemoryBagStore = InMemoryBagStore(), signedInAs userId: Int? = nil) {
        self.store = store
        self.sessions = CurrentValueSubject(Self.session(forUserId: userId))
        self.di = BagDI(
            getSession: StubGetSession(sessions: sessions),
            observeSession: StubObserveSession(sessions: sessions),
            store: store
        )

        di.observeBagUseCase()
            .sink { [weak self] in self?.bag = $0 }
            .store(in: &cancellables)
    }

    func choose(productId: Int, atPrice price: Double) {
        di.addItemToBagUseCase(BagItem(id: productId, lastKnownPrice: price))
    }

    func changeQuantity(ofProductId productId: Int, to quantity: Int) {
        di.setBagItemQuantityUseCase(itemId: productId, to: quantity)
    }

    func remove(productId: Int) {
        di.setBagItemQuantityUseCase(itemId: productId, to: 0)
    }

    func signIn(asUserId userId: Int) {
        sessions.send(Self.session(forUserId: userId))
    }

    func signOut() {
        sessions.send(.guest)
    }

    private static func session(forUserId userId: Int?) -> Session {
        guard let userId else { return .guest }
        return .authenticated(User(id: userId, email: "", firstName: "", lastName: ""))
    }
}

private struct StubGetSession: GetSessionUseCase, @unchecked Sendable {
    let sessions: CurrentValueSubject<Session, Never>

    @MainActor
    func callAsFunction() -> Session { sessions.value }
}

private struct StubObserveSession: ObserveSessionUseCase, @unchecked Sendable {
    let sessions: CurrentValueSubject<Session, Never>

    @MainActor
    func callAsFunction() -> AnyPublisher<Session, Never> { sessions.eraseToAnyPublisher() }
}

final class InMemoryBagStore: BagStore, @unchecked Sendable {
    private let lock = NSLock()
    private var bags: [String: Bag]

    init(seeded: [String: Bag] = [:]) {
        self.bags = seeded
    }

    func getBag(forUserKey userKey: String) -> Bag {
        lock.withLock { bags[userKey] ?? Bag() }
    }

    func setBag(_ bag: Bag, forUserKey userKey: String) async {
        lock.withLock { bags[userKey] = bag }
    }
}
