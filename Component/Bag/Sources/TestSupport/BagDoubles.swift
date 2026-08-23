import Bag
import Combine

/// A fake in Meszaros' sense: a working implementation, unfit for production.
/// It keeps the bag in memory rather than on disk, so a journey can put things
/// in it and read them back without a store being involved.
///
/// Published here because `BagRepository` belongs to this package, so the thing
/// standing in for it does too. `@unchecked Sendable` because the subjects it
/// holds are not — the same bargain every other double in this codebase makes,
/// and one a test target never had to state out loud because it was not checked
/// as strictly as an ordinary module is.
///
/// Every member is `public`: a shared module is
/// consumed with a plain `import`, and `@testable` only appears to work — it
/// compiles against internal members and then fails at the link step.
public final class InMemoryBagRepository: BagRepository, @unchecked Sendable {
    private let bagSubject = CurrentValueSubject<Bag, Never>(Bag())
    private let noticesSubject = CurrentValueSubject<Notices, Never>(Notices())

    public init() {}

    public var bag: Bag { bagSubject.value }
    public var bagPublisher: AnyPublisher<Bag, Never> { bagSubject.eraseToAnyPublisher() }
    public var notices: Notices { noticesSubject.value }
    public var noticesPublisher: AnyPublisher<Notices, Never> { noticesSubject.eraseToAnyPublisher() }

    public func save(bag: Bag, notices: Notices) {
        bagSubject.value = bag
        noticesSubject.value = notices
    }
}
