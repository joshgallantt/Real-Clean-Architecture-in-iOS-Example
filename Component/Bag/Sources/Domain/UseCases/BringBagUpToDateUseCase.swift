import Product

public protocol BringBagUpToDateUseCase: Sendable {
    /// Brings the bag up to date with what the catalog currently says. Covering only
    /// some of the bag is fine — the rest is left alone.
    @MainActor
    func callAsFunction(against products: [Product])
}

public struct DefaultBringBagUpToDateUseCase: BringBagUpToDateUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(against products: [Product]) {
        let upToDate = BagReconciliation.reconcile(
            bag: repository.bag,
            changes: repository.changes,
            against: products
        )

        // Saving an unchanged bag would wake everything watching it for nothing, and on a
        // screen that does this every time it appears, that is most of the time.
        guard upToDate.bag != repository.bag || upToDate.changes != repository.changes else {
            return
        }
        repository.save(bag: upToDate.bag, changes: upToDate.changes)
    }
}
