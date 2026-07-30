import Combine
import Foundation
import Bag
import BagData
import BagDI
import Money
import Product
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
    private(set) var news = BagChanges()

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

        di.observeBagChangesUseCase()
            .sink { [weak self] in self?.news = $0 }
            .store(in: &cancellables)
    }

    func choose(productId: Int, atPrice price: Decimal) {
        di.addItemToBagUseCase(
            BagItem(productId: ProductID(rawValue: productId), lastKnownPrice: usd(price))
        )
    }

    func changeQuantity(ofProductId productId: Int, to quantity: Int) {
        di.setBagItemQuantityUseCase(productId: ProductID(rawValue: productId), to: quantity)
    }

    func remove(productId: Int) {
        di.setBagItemQuantityUseCase(productId: ProductID(rawValue: productId), to: 0)
    }

    /// What the shop now says about everything in the bag.
    func shopSays(_ shopSays: ShopSays...) {
        di.bringBagUpToDateUseCase(against: shopSays)
    }

    func seen(productId: Int) {
        di.acknowledgeBagChangeUseCase(productId: ProductID(rawValue: productId))
    }

    func signIn(asUserId userId: Int) {
        sessions.send(Self.session(forUserId: userId))
    }

    func signOut() {
        sessions.send(.guest)
    }

    private static func session(forUserId userId: Int?) -> Session {
        guard let userId else { return .guest }
        return .authenticated(
            User(
                id: UserID(rawValue: userId),
                email: Email("shopper@example.com"),
                name: PersonName(first: "Ada", last: nil)
            )
        )
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
    private var bags: [BagOwner: (bag: Bag, changes: BagChanges)]

    init(seeded: [BagOwner: (bag: Bag, changes: BagChanges)] = [:]) {
        self.bags = seeded
    }

    func getBag(for owner: BagOwner) -> (bag: Bag, changes: BagChanges) {
        lock.withLock { bags[owner] ?? (Bag(), BagChanges()) }
    }

    func setBag(_ bag: Bag, changes: BagChanges, for owner: BagOwner) async {
        lock.withLock { bags[owner] = (bag, changes) }
    }
}

// MARK: - Fixtures

func usd(_ amount: Decimal) -> Money {
    Money(amount: amount, currency: .usd)
}

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}

func shopSells(_ id: Int, at price: Decimal, remaining: Int = 10) -> ShopSays {
    ShopSays(productId: pid(id), price: usd(price), availability: .inStock(remaining: remaining))
}

func shopHasSoldOutOf(_ id: Int) -> ShopSays {
    ShopSays(productId: pid(id), price: usd(1), availability: .outOfStock)
}
