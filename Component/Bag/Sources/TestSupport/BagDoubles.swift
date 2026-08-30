import Bag
import Combine
import Product

/// Stand-ins for the protocols this component declares, published so that every
/// package whose tests need a bag shares one definition of each.
///
/// Winters, Manshreck & Wright, *Software Engineering at Google* (2020), Ch. 13
/// — Test Doubles: the fake belongs to whoever owns the API, not to whoever
/// calls it. When callers write their own, one protocol collects a stub per
/// consumer, each drifting from the real behaviour on its own schedule, and
/// every suite goes on passing while they disagree. Before this file existed
/// `SpySetBagItemQuantity` had been written twice, character for character, and
/// `StubObserveBag` twice with one copy quietly missing `send(_:)`.
///
/// Every member is `public`: a shared module is consumed with a plain `import`,
/// and `@testable` only appears to be a substitute — it compiles against
/// internal members and then fails at the link step.
@MainActor
public final class StubObserveBag: ObserveBagUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Bag, Never>

    public init(_ bag: Bag = Bag()) {
        subject = CurrentValueSubject(bag)
    }

    public func callAsFunction() -> AnyPublisher<Bag, Never> { subject.eraseToAnyPublisher() }

    public func send(_ bag: Bag) { subject.send(bag) }
}

@MainActor
public final class StubObserveNotices: ObserveNoticesUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Notices, Never>

    public init(_ notices: Notices = Notices()) {
        subject = CurrentValueSubject(notices)
    }

    public func callAsFunction() -> AnyPublisher<Notices, Never> { subject.eraseToAnyPublisher() }

    public func send(_ notices: Notices) { subject.send(notices) }
}

@MainActor
public final class StubObserveBagItemQuantity: ObserveBagItemQuantityUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Int, Never>

    public init(_ quantity: Int = 0) {
        subject = CurrentValueSubject(quantity)
    }

    public func callAsFunction(productId: ProductID) -> AnyPublisher<Int, Never> {
        subject.eraseToAnyPublisher()
    }
}

@MainActor
public final class SpySetBagItemQuantity: SetBagItemQuantityUseCase, @unchecked Sendable {
    public private(set) var calls: [(productId: ProductID, quantity: Int)] = []

    public init() {}

    public func callAsFunction(productId: ProductID, to quantity: Int) {
        calls.append((productId, quantity))
    }
}

@MainActor
public final class SpyAddItemToBag: AddItemToBagUseCase, @unchecked Sendable {
    public private(set) var added: [BagItem] = []

    public init() {}

    public func callAsFunction(_ item: BagItem) {
        added.append(item)
    }
}

@MainActor
public final class SpyAcknowledgeNotices: AcknowledgeNoticesUseCase, @unchecked Sendable {
    public private(set) var acknowledged: [ProductID] = []

    public init() {}

    public func callAsFunction(aboutProductId productId: ProductID) {
        acknowledged.append(productId)
    }
}

@MainActor
public final class StubBringBagUpToDate: BringBagUpToDateUseCase, @unchecked Sendable {
    public var products: [Product] = []
    public private(set) var callCount = 0

    public init() {}

    public func callAsFunction() async -> [Product] {
        callCount += 1
        return products
    }
}

/// A fake in Meszaros' sense: a working implementation, unfit for production.
/// It keeps the bag in memory rather than on disk, so a journey can put things
/// in it and read them back without a store being involved.
///
/// `@unchecked Sendable` because the subjects it holds are not — the same
/// bargain every other double here makes, and one a test target never had to
/// state out loud because it was not checked as strictly as an ordinary module.
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
