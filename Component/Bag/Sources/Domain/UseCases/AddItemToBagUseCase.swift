/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol AddItemToBagUseCase: Sendable {
    @MainActor
    func callAsFunction(_ item: BagItem)
}

public struct DefaultAddItemToBagUseCase: AddItemToBagUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(_ item: BagItem) {
        repository.save(
            bag: repository.bag.adding(item),
            changes: repository.changes.acknowledging(productId: item.productId)
        )
    }
}
