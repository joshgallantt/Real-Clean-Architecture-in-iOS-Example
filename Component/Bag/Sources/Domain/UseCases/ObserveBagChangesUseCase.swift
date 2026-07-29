import Combine

public protocol ObserveBagChangesUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<BagChanges, Never>
}

public struct DefaultObserveBagChangesUseCase: ObserveBagChangesUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<BagChanges, Never> {
        repository.changesPublisher
    }
}
