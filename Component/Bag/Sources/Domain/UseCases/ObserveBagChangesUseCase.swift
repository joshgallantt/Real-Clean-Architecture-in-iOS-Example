import Combine

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol ObserveBagChangesUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<BagChanges, Never>
}

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: the rule about
/// which notices are still worth telling is applied here, so a screen is handed news it can render
/// as-is rather than being trusted to filter it. Deciding on read means a bag and a notice list
/// that have drifted apart correct themselves instead of showing nonsense.
///
/// Evans, *Domain-Driven Design* (2003) — Side-Effect-Free Functions.
public struct DefaultObserveBagChangesUseCase: ObserveBagChangesUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<BagChanges, Never> {
        repository.changesPublisher
            .combineLatest(repository.bagPublisher)
            .map { changes, bag in Self.worthTelling(changes, about: bag) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    static func worthTelling(_ changes: BagChanges, about bag: Bag) -> BagChanges {
        BagChanges(
            changes.all.filter { change in
                change.isAboutAProductStillInTheBag == bag.holds(productId: change.productId)
            }
        )
    }
}
