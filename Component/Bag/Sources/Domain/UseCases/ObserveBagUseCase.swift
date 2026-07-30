import Combine

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
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
