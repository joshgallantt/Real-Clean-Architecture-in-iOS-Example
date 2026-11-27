import Combine
import Product

// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
// Service Layer. Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
//
// Everything a shopper can ask of their stock alerts. Those three hold for every protocol below, so
// they are cited once; a comment on any one of them says only what is true of that one.

public protocol ObserveProductHasStockAlertUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never>
}

/// Every alert the shopper has set, for whoever needs to know that they changed. The products
/// below depend on the shop as well, so they cannot be a publisher of stored state — this is the
/// signal that they are worth asking for again.
public protocol ObserveStockAlertsUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<StockAlerts, Never>
}

/// One bell, with a state — the setter for what `ObserveProductHasStockAlertUseCase` reports. A
/// caller says what it wants to be true and the domain works out what that takes, so the button
/// that draws the bell never has to pick between setting and clearing from its own state.
public protocol SetProductStockAlertUseCase: Sendable {
    @discardableResult
    func callAsFunction(productId: ProductID, isOn: Bool) async -> Result<Void, StockAlertError>
}

/// Evans, Ch. 9 — Making Implicit Concepts Explicit: the products the shopper has an alert on, as
/// the shop has them today — the ones that are back first, then the ones still sold out. One list,
/// because it is one set of alerts: which of them have come back is something each product already
/// says about itself.
///
/// A product keeps its alert when it comes back. The alert is wanting to be told, and whether the
/// shop has any is a fact about the shop, not about the shopper — so nothing is cleared on their
/// behalf, and something that sells out again is simply waited on again. Only
/// `SetProductStockAlertUseCase(isOn: false)` clears one.
public protocol GetStockAlertProductsUseCase: Sendable {
    func callAsFunction() async -> Result<[Product], StockAlertError>
}
