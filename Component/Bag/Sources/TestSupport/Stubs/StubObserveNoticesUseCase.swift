import Bag
import Combine
import Product
import ProductTestSupport

@MainActor
public final class StubObserveNoticesUseCase: ObserveNoticesUseCase {
    private let subject: CurrentValueSubject<Notices, Never>

    public init(_ notices: Notices = Notices()) {
        subject = CurrentValueSubject(notices)
    }

    public func callAsFunction() -> AnyPublisher<Notices, Never> { subject.eraseToAnyPublisher() }

    public func send(_ notices: Notices) { subject.send(notices) }
}
