import Bag
import Combine
import Product
import ProductTestSupport

/// A fake in Meszaros' sense: a working implementation, unfit for production.
/// It keeps the bag in memory rather than on disk, so a journey can put things
/// in it and read them back without a store being involved.
///
/// `@unchecked Sendable` because the subjects it holds are not — the same
/// bargain every other double here makes, and one a test target never had to
/// state out loud because it was not checked as strictly as an ordinary module.
@MainActor
public final class FakeBagRepository: BagRepository {
    private let bagSubject: CurrentValueSubject<Bag, Never>
    private let noticesSubject: CurrentValueSubject<Notices, Never>

    public init(bag: Bag = Bag(), notices: Notices = Notices()) {
        bagSubject = CurrentValueSubject(bag)
        noticesSubject = CurrentValueSubject(notices)
    }

    public var bag: Bag { bagSubject.value }
    public var bagPublisher: AnyPublisher<Bag, Never> { bagSubject.eraseToAnyPublisher() }
    public var notices: Notices { noticesSubject.value }
    public var noticesPublisher: AnyPublisher<Notices, Never> { noticesSubject.eraseToAnyPublisher() }

    public func save(bag: Bag, notices: Notices) {
        bagSubject.value = bag
        noticesSubject.value = notices
    }
}
