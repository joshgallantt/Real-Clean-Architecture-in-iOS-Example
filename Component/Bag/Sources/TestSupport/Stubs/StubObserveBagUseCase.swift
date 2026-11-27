import Bag
import Combine

@MainActor
public final class StubObserveBagUseCase: ObserveBagUseCase {
    private let subject: CurrentValueSubject<Bag, Never>

    public init(_ bag: Bag = Bag()) {
        subject = CurrentValueSubject(bag)
    }

    public func callAsFunction() -> AnyPublisher<Bag, Never> { subject.eraseToAnyPublisher() }
}
