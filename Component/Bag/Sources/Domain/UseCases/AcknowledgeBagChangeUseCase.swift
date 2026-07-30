import Product

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol AcknowledgeBagChangeUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID)
}

public struct DefaultAcknowledgeBagChangeUseCase: AcknowledgeBagChangeUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(productId: ProductID) {
        repository.save(
            bag: repository.bag,
            changes: repository.changes.acknowledging(productId: productId)
        )
    }
}
