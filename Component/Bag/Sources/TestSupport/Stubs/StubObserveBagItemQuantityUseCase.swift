import Bag
import Combine
import Product
import ProductTestSupport

@MainActor
public final class StubObserveBagItemQuantityUseCase: ObserveBagItemQuantityUseCase {
    private let subject: CurrentValueSubject<Int, Never>

    public init(_ quantity: Int = 0) {
        subject = CurrentValueSubject(quantity)
    }

    public func callAsFunction(productId: ProductID) -> AnyPublisher<Int, Never> {
        subject.eraseToAnyPublisher()
    }
}
