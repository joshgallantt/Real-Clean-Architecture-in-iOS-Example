import Combine

public protocol ObserveBagItemQuantityUseCase: Sendable {
    @MainActor
    func callAsFunction(itemId: Int) -> AnyPublisher<Int, Never>
}

public struct DefaultObserveObserveBagItemQuantityUseCase: ObserveBagItemQuantityUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    /// Only this one line's quantity, and only when it actually changes — a badge on a
    /// product tile has no interest in the rest of the bag moving around it.
    @MainActor
    public func callAsFunction(itemId: Int) -> AnyPublisher<Int, Never> {
        repository.bagPublisher
            .map { $0.quantity(forItemId: itemId) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
