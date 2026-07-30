import Combine

public protocol ObserveBagChangesUseCase: Sendable {
    /// What the shopper still needs to be told, and only what is still worth telling them.
    @MainActor
    func callAsFunction() -> AnyPublisher<BagChanges, Never>
}

public struct DefaultObserveBagChangesUseCase: ObserveBagChangesUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    /// Reads the bag alongside the notices, because whether a notice is worth mentioning
    /// depends on both and neither one can answer it alone. Deciding here means a screen
    /// is handed news it can show as-is, rather than being trusted to apply the rule —
    /// which is how the rule ends up living in a view.
    @MainActor
    public func callAsFunction() -> AnyPublisher<BagChanges, Never> {
        repository.changesPublisher
            .combineLatest(repository.bagPublisher)
            .map { changes, bag in Self.worthTelling(changes, about: bag) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// A price or a shortage is news about something the shopper is buying, so either one
    /// about a line no longer in the bag is news about nothing. A product being gone is news
    /// about something absent, so it only stands while it is absent — choose it again and
    /// there is nothing to report.
    ///
    /// Decided when the notices are read rather than when they are written. The bag and the
    /// notices are kept together but written one after the other, and a process that dies in
    /// between would leave the pair disagreeing. Deciding on the way out means the
    /// disagreement corrects itself instead of persisting.
    static func worthTelling(_ changes: BagChanges, about bag: Bag) -> BagChanges {
        BagChanges(
            changes.all.filter { change in
                change.isAboutAProductStillInTheBag == bag.holds(productId: change.productId)
            }
        )
    }
}
