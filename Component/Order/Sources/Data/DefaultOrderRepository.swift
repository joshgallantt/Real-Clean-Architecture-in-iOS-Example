import Combine
import Foundation
import Order
import Session

@MainActor
/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Repositories. Fowler, *PoEAA* (2002), Ch. 13 —
/// Repository: it keeps and hands back aggregates and decides nothing about what they mean.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: takes an owner and a stream
/// of owners, never a `Session`. It needs to know whose orders are live, not to understand identity.
public final class DefaultOrderRepository: OrderRepository {
    private let store: OrderStore
    private let ordersSubject: CurrentValueSubject<Orders, Never>
    private var owner: UserID?
    private var cancellables = Set<AnyCancellable>()
    private var pendingWrite: Task<Void, Never>?

    public init(
        store: OrderStore,
        owner: UserID?,
        ownerPublisher: AnyPublisher<UserID?, Never>
    ) {
        self.store = store
        self.owner = owner
        self.ordersSubject = CurrentValueSubject(store.getOrders(for: owner))

        ownerPublisher
            .sink { [weak self] owner in
                self?.switchOwner(to: owner)
            }
            .store(in: &cancellables)
    }

    public var orders: Orders { ordersSubject.value }

    public var ordersPublisher: AnyPublisher<Orders, Never> { ordersSubject.eraseToAnyPublisher() }

    public func save(_ order: Order) {
        let orders = ordersSubject.value.adding(order)
        ordersSubject.value = orders

        let store = store
        let owner = owner
        let previous = pendingWrite
        pendingWrite = Task {
            await previous?.value
            await store.setOrders(orders, for: owner)
        }
    }

    func flushPendingWrites() async {
        await pendingWrite?.value
    }

    /// Signing out takes the orders off the screen with it. They are not gone — they are filed
    /// under whoever placed them, and signing back in brings them back.
    private func switchOwner(to owner: UserID?) {
        guard owner != self.owner else { return }
        self.owner = owner
        ordersSubject.value = store.getOrders(for: owner)
    }
}
