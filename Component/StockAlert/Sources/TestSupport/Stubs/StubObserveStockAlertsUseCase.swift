import Combine
import StockAlert

@MainActor
public final class StubObserveStockAlertsUseCase: ObserveStockAlertsUseCase {
    private let subject = CurrentValueSubject<StockAlerts, Never>(StockAlerts())

    public init() {}

    public func send(_ stockAlerts: StockAlerts) { subject.send(stockAlerts) }

    public func callAsFunction() -> AnyPublisher<StockAlerts, Never> { subject.eraseToAnyPublisher() }
}
