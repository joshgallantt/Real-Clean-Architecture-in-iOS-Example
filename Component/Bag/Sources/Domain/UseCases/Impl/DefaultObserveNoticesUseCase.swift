import Combine

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: the rule about which
/// notices are still worth telling is applied here, so a screen is handed news it can render as-is
/// rather than being trusted to filter it.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 10 — Side-Effect-Free Functions.
public struct DefaultObserveNoticesUseCase: ObserveNoticesUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<Notices, Never> {
        repository.noticesPublisher
            .combineLatest(repository.bagPublisher)
            .map { notices, bag in Self.stillTrue(notices, of: bag) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// A notice about a line — what it costs, how many are left — is only true while the line is
    /// still there. A notice that something has *gone* is only true while it is not. Either way the
    /// bag is what decides, so a bag and a list of notices that have drifted apart correct
    /// themselves on read instead of showing nonsense.
    static func stillTrue(_ notices: Notices, of bag: Bag) -> Notices {
        Notices(
            notices.all.filter { notice in
                notice.isAboutSomethingGone
                    ? !bag.holds(productId: notice.productId)
                    : bag.holds(productId: notice.productId)
            }
        )
    }
}
