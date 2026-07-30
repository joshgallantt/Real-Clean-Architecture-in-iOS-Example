import Combine
import Product

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol ObserveBagItemQuantityUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) -> AnyPublisher<Int, Never>
}

public struct DefaultObserveBagItemQuantityUseCase: ObserveBagItemQuantityUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    /// Martin, *Clean Architecture* (2017), Ch. 10 — Interface Segregation Principle: one line's
    /// count, and only when it changes. A badge on a product tile has no interest in the rest of
    /// the bag.
    public func callAsFunction(productId: ProductID) -> AnyPublisher<Int, Never> {
        repository.bagPublisher
            .map { $0.quantity(of: productId) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
