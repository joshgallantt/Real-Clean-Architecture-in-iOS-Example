import Foundation
import Product

/// Evans, *Domain-Driven Design* (2003) — Aggregates: the root, enforcing its own invariants on the
/// way in — one ask per product, most recent first. Asking twice about the same thing is one ask,
/// because a shopper who taps a bell again has not asked for two messages.
///
/// Evans — Side-Effect-Free Functions: every change returns a new `StockAlerts`, so the invariants
/// are re-established by the initialiser on every path rather than defended after the fact.
public struct StockAlerts: Equatable, Sendable {
    public let alerts: [StockAlert]

    public init(alerts: [StockAlert] = []) {
        var seen: Set<ProductID> = []
        self.alerts = alerts
            .filter { seen.insert($0.productId).inserted }
            .sorted { $0.dateAsked > $1.dateAsked }
    }

    public var isEmpty: Bool { alerts.isEmpty }

    public var count: Int { alerts.count }

    /// Whether the shopper is *still* waiting. A bell that stayed lit after the thing came back
    /// would be offering to tell them something they have already been told.
    public func waitingFor(productId: ProductID) -> Bool {
        alerts.contains { $0.productId == productId && $0.isWaiting }
    }

    /// Still to come, newest ask first.
    public var waiting: [StockAlert] { alerts.filter(\.isWaiting) }

    /// Arrived, and not yet acknowledged. This is the payoff of the whole feature, so it is a list
    /// in its own right rather than something a screen has to sieve out of the one above.
    public var back: [StockAlert] { alerts.filter { !$0.isWaiting } }

    public func adding(_ alert: StockAlert) -> StockAlerts {
        guard !alerts.contains(where: { $0.productId == alert.productId }) else { return self }
        return StockAlerts(alerts: alerts + [alert])
    }

    /// Evans, *Domain-Driven Design* (2003), Ch. 10 — Side-Effect-Free Functions: the shop has put
    /// these back, so the asks about them are answered. One already marked keeps the moment it was
    /// first marked — a shopper is told a thing is back once, not again every time a screen looks.
    public func marking(_ productIds: Set<ProductID>, backAt moment: Date) -> StockAlerts {
        StockAlerts(
            alerts: alerts.map { alert in
                guard productIds.contains(alert.productId), alert.isWaiting else { return alert }
                return alert.markedBack(at: moment)
            }
        )
    }

    public func removing(productId: ProductID) -> StockAlerts {
        guard waitingFor(productId: productId) else { return self }
        return StockAlerts(alerts: alerts.filter { $0.productId != productId })
    }
}
