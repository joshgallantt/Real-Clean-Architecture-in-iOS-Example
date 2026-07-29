public protocol ReconcileBagUseCase: Sendable {
    /// Brings the bag up to date with what the shop currently says. Whatever is known is
    /// enough — prices without stock, or stock without prices, both do useful work.
    @MainActor
    func callAsFunction(prices: [Int: Double], inStock: [Int: Bool])
}

public struct DefaultReconcileBagUseCase: ReconcileBagUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(prices: [Int: Double], inStock: [Int: Bool]) {
        let bag = repository.bag
        let reconciled = bag.reconciled(prices: prices, inStock: inStock)

        // Saving an unchanged bag would wake everything watching it for nothing, and on
        // a screen that reconciles every time it appears, that is most of the time.
        guard reconciled != bag else { return }
        repository.save(reconciled)
    }
}
