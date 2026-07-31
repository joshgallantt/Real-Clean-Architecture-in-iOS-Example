import Combine
import Foundation
import Product
import Session
import StockAlert

@MainActor
/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Repositories. Fowler, *PoEAA* (2002), Ch. 13 —
/// Repository: it keeps and hands back aggregates and decides nothing about what they mean.
///
/// Two sources, reconciled here and nowhere else. The store is what a shopper's own device
/// remembers, so a bell is right the instant the app opens and stays right with no signal. The
/// client is the shop, and the shop is the only thing that knows whether something is back on the
/// shelf. Above this, neither exists: the domain asks a repository.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: takes an owner and a
/// stream of owners, never a `Session`. It needs to know whose alerts are live, not to understand
/// identity — the same shape the bag's, the wishlist's and the history's take.
public final class DefaultStockAlertRepository: StockAlertRepository {
    private let store: StockAlertStore
    private let client: StockAlertClient
    private let subject: CurrentValueSubject<StockAlerts, Never>
    private var owner: UserID?
    private var cancellables = Set<AnyCancellable>()

    public init(
        store: StockAlertStore,
        client: StockAlertClient,
        owner: UserID?,
        ownerPublisher: AnyPublisher<UserID?, Never>
    ) {
        self.store = store
        self.client = client
        self.owner = owner
        self.subject = CurrentValueSubject(StockAlerts(alerts: store.getAlerts(for: owner)))

        ownerPublisher
            .sink { [weak self] owner in
                self?.switchOwner(to: owner)
            }
            .store(in: &cancellables)
    }

    public var alerts: StockAlerts { subject.value }

    public var alertsPublisher: AnyPublisher<StockAlerts, Never> { subject.eraseToAnyPublisher() }

    /// Fowler, *PoEAA* (2002), Ch. 13 — Repository: kept first, published second. A bell that filled
    /// before the ask was written down would be a promise nothing had recorded.
    ///
    /// The shop is told afterwards, and being unable to tell it is not a reason to lose the ask.
    /// Because the whole set goes over rather than a change to it, the next save repairs a sync that
    /// never landed — the shop is told what this shopper is waiting on, not what just happened, so
    /// there is no missed edit to replay.
    public func save(_ alerts: StockAlerts) async throws {
        try await store.setAlerts(alerts.alerts, for: owner)
        subject.value = alerts
        await tellTheShop(alerts)
    }

    public func whatTheShopSaysIsBack() async throws -> [ProductID] {
        guard let owner else { return [] }
        return try await client.backInStock(for: owner)
    }

    private func tellTheShop(_ alerts: StockAlerts) async {
        guard let owner else { return }
        try? await client.setAlerts(alerts.alerts.map(\.productId), for: owner)
    }

    /// Signing in re-tells the shop what this shopper is waiting on, so a device that made asks
    /// while the shop could not be reached catches up the moment it can be.
    private func switchOwner(to owner: UserID?) {
        guard owner != self.owner else { return }
        self.owner = owner

        let kept = StockAlerts(alerts: store.getAlerts(for: owner))
        subject.value = kept

        Task { [weak self] in await self?.tellTheShop(kept) }
    }
}
