import Combine

public protocol ObserveBagUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Bag, Never>
}

public struct DefaultObserveBagUseCase: ObserveBagUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<Bag, Never> {
        repository.bagPublisher
    }
}
