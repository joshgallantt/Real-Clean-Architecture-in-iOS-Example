import Product

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
/// Service Layer.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces: a shopper says
/// they have seen what happened to one product, so every notice about that product goes.
public protocol AcknowledgeNoticesUseCase: Sendable {
    @MainActor
    func callAsFunction(aboutProductId productId: ProductID)
}

public struct DefaultAcknowledgeNoticesUseCase: AcknowledgeNoticesUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(aboutProductId productId: ProductID) {
        repository.save(
            bag: repository.bag,
            notices: repository.notices.acknowledging(productId)
        )
    }
}
