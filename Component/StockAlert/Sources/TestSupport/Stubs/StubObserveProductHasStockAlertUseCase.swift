import Combine
import Product
import StockAlert

@MainActor
public final class StubObserveProductHasStockAlertUseCase: ObserveProductHasStockAlertUseCase {
    private let subject: CurrentValueSubject<Bool, Never>

    public init(_ isOn: Bool = false) {
        subject = CurrentValueSubject(isOn)
    }

    public func send(_ isOn: Bool) { subject.value = isOn }

    public func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never> { subject.eraseToAnyPublisher() }
}
