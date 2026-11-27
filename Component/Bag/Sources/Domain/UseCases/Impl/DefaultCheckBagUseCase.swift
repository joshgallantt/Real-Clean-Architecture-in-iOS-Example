import Product

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: application work — it reads the bag
/// and asks another component's use case about it. What the answer means for the bag is not decided
/// here: that is `Bag.checked(against:asked:)`, which needs no shop to be tested against.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 5 — Services: behaviour that needs two components,
/// and holds no state.
public struct DefaultCheckBagUseCase: CheckBagUseCase {
    private let repository: BagRepository
    private let lookUpProducts: LookUpProductsUseCase

    public init(repository: BagRepository, lookUpProducts: LookUpProductsUseCase) {
        self.repository = repository
        self.lookUpProducts = lookUpProducts
    }

    @MainActor
    public func callAsFunction() async -> CheckedBag {
        let asked = Set(repository.bag.items.map(\.productId))

        /// A shop that could not be reached has said nothing at all, and nothing is concluded from
        /// nothing. Only an answer is evidence — which is what keeps a dropped connection from
        /// reading as a shop that has closed down and emptying the bag. An empty bag is the same
        /// case from the other side: there is nothing to ask about.
        guard !asked.isEmpty, case .success(let products) = await lookUpProducts(ids: Array(asked)) else {
            return repository.bag.checked(against: [], asked: [])
        }

        /// The bag as it is now, not as it was when the shop was asked. Anything put in while the
        /// shop was answering was not asked about, so it is left as it is.
        return repository.bag.checked(against: products, asked: asked)
    }
}
