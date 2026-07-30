import Combine

/// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle.
///
/// Evans, *Domain-Driven Design* (2003) — Repositories. Fowler, *PoEAA* (2002) — Repository;
/// Separated Interface.
public protocol StockAlertRepository: Sendable {
    @MainActor
    var alerts: StockAlerts { get }

    @MainActor
    var alertsPublisher: AnyPublisher<StockAlerts, Never> { get }

    /// Throws when the ask could not be kept, so nothing can promise a shopper something that was
    /// never written down. What is published is what was kept.
    @MainActor
    func save(_ alerts: StockAlerts) async throws
}
