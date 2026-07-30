import Combine
import Foundation
import Session
import StockAlert

@MainActor
/// Evans, *Domain-Driven Design* (2003) — Repositories. Fowler, *PoEAA* (2002) — Repository: it
/// keeps and hands back aggregates and decides nothing about what they mean.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: takes an owner and a
/// stream of owners, never a `Session`. It needs to know whose alerts are live, not to understand
/// identity — the same shape the bag's, the wishlist's and the history's take.
public final class DefaultStockAlertRepository: StockAlertRepository {
    private let store: StockAlertStore
    private let subject: CurrentValueSubject<StockAlerts, Never>
    private var owner: UserID?
    private var cancellables = Set<AnyCancellable>()

    public init(
        store: StockAlertStore,
        owner: UserID?,
        ownerPublisher: AnyPublisher<UserID?, Never>
    ) {
        self.store = store
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

    /// Fowler, *PoEAA* (2002) — Repository: kept first, published second. A bell that filled before
    /// the ask was written down would be a promise nothing had recorded.
    public func save(_ alerts: StockAlerts) async throws {
        try await store.setAlerts(alerts.alerts, for: owner)
        subject.value = alerts
    }

    private func switchOwner(to owner: UserID?) {
        guard owner != self.owner else { return }
        self.owner = owner
        subject.value = StockAlerts(alerts: store.getAlerts(for: owner))
    }
}
