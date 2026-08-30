import Bag
import Combine
import Product
import ProductTestSupport

@MainActor
public final class StubObserveBag: ObserveBagUseCase {
    private let subject: CurrentValueSubject<Bag, Never>

    public init(_ bag: Bag = Bag()) {
        subject = CurrentValueSubject(bag)
    }

    public func callAsFunction() -> AnyPublisher<Bag, Never> { subject.eraseToAnyPublisher() }

    public func send(_ bag: Bag) { subject.send(bag) }
}
