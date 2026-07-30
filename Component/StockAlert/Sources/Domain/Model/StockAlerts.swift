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

    public func waitingFor(productId: ProductID) -> Bool {
        alerts.contains { $0.productId == productId }
    }

    public func adding(_ alert: StockAlert) -> StockAlerts {
        guard !waitingFor(productId: alert.productId) else { return self }
        return StockAlerts(alerts: alerts + [alert])
    }

    public func removing(productId: ProductID) -> StockAlerts {
        guard waitingFor(productId: productId) else { return self }
        return StockAlerts(alerts: alerts.filter { $0.productId != productId })
    }
}
