import Combine

/// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Repositories. Fowler, *PoEAA* (2002), Ch. 13 —
/// Repository; Ch. 18 — Separated Interface.
public protocol OrderRepository: Sendable {
    @MainActor
    var orders: Orders { get }

    @MainActor
    var ordersPublisher: AnyPublisher<Orders, Never> { get }

    /// Does not throw, and that is the difference between this and `StockAlertRepository.save`.
    /// An ask that was never written down is a promise nobody made, so that one throws and the
    /// shopper is told. By the time an order is saved the money has already moved — refusing it
    /// here would tell a shopper a payment failed that did not.
    ///
    /// Keeping the record is therefore best-effort: the payment is the fact, and a shop with a
    /// real processor behind it reconciles against that rather than against this file.
    @MainActor
    func save(_ order: Order)
}
