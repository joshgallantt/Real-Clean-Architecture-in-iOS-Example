import Combine
import StockAlert

/// A fake in Meszaros' sense: a working implementation, unfit for production. It keeps the alerts
/// in memory, so the real use cases genuinely read, apply and save. `whenItCannotKeep` is the one
/// thing a disk does that memory does not.
@MainActor
public final class FakeStockAlertRepository: StockAlertRepository {
    private let subject: CurrentValueSubject<StockAlerts, Never>

    public var whenItCannotKeep = false

    public init(stockAlerts: StockAlerts = StockAlerts()) {
        subject = CurrentValueSubject(stockAlerts)
    }

    public var stockAlerts: StockAlerts { subject.value }
    public var stockAlertsPublisher: AnyPublisher<StockAlerts, Never> { subject.eraseToAnyPublisher() }

    /// The yield is the round trip. A store that keeps something suspends before it has kept it,
    /// and a shopper can tap again inside that gap — which is only true of this stand-in if it
    /// suspends too.
    public func save(_ stockAlerts: StockAlerts) async throws {
        await Task.yield()
        if whenItCannotKeep { throw CouldNotKeep() }
        subject.value = stockAlerts
    }

    public struct CouldNotKeep: Error {}
}
