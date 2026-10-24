import Combine
import Product
import Waitlist

@MainActor
public final class StubObserveProductIsWaitlistedUseCase: ObserveProductIsWaitlistedUseCase {
    private let subject: CurrentValueSubject<Bool, Never>

    public init(_ isWaitlisted: Bool = false) {
        subject = CurrentValueSubject(isWaitlisted)
    }

    public func send(_ isWaitlisted: Bool) { subject.value = isWaitlisted }

    public func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never> { subject.eraseToAnyPublisher() }
}
