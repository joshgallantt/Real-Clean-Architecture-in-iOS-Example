import Combine
import Product
import Session
import StockAlert

@MainActor
public final class StubObserveWaitlistStatusUseCase: ObserveWaitlistStatusUseCase {
    private let subject: CurrentValueSubject<Bool, Never>

    public init(_ isWaiting: Bool = false) {
        subject = CurrentValueSubject(isWaiting)
    }

    public func send(_ isWaiting: Bool) { subject.value = isWaiting }

    public func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never> { subject.eraseToAnyPublisher() }
}
