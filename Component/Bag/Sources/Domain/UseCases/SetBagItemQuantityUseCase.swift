import Product

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol SetBagItemQuantityUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID, to quantity: Int)
}

public struct DefaultSetBagItemQuantityUseCase: SetBagItemQuantityUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(productId: ProductID, to quantity: Int) {
        let bag = repository.bag.changingQuantity(of: productId, to: quantity)

        let changes = bag.holds(productId: productId)
            ? repository.changes
            : repository.changes.acknowledging(productId: productId)

        repository.save(bag: bag, changes: changes)
    }
}
