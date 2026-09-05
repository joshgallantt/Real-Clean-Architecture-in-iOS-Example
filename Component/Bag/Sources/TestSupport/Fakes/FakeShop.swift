import Bag
import Combine
import Foundation
import Product
import ProductTestSupport

/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: only two things are faked —
/// where the bag is kept and what the catalog answers. The use cases the screen is handed are the
/// real ones, built on this as their repository.
///
/// Fowler, *PoEAA* (2002), Ch. 13 — Repository; Ch. 18 — Gateway.
///
/// The repository half is `FakeBagRepository`, held rather than rewritten.
/// It had been rewritten here — the same subjects, the same accessors, the same
/// `save` — which is two fakes of one protocol that nothing would have made
/// disagree out loud. What this adds is a catalogue and the real use cases
/// assembled over both, which is a driver's job rather than a fake's.
@MainActor
public final class FakeShop: BagRepository {
    private let catalogLock = NSLock()
    private let repository: FakeBagRepository
    private nonisolated(unsafe) var _lookups: [[ProductID]] = []
    private nonisolated(unsafe) var _catalog: [Product]
    private nonisolated(unsafe) var _cannotBeReached = false

    public nonisolated var lookups: [[ProductID]] { catalogLock.withLock { _lookups } }
    public var currentBag: Bag { repository.bag }
    public var currentNotices: Notices { repository.notices }

    public nonisolated var catalog: [Product] {
        get { catalogLock.withLock { _catalog } }
        set { catalogLock.withLock { _catalog = newValue } }
    }

    /// Told apart from a shop that answers with nothing, because the two mean opposite things: one
    /// has stopped selling everything, the other has said nothing at all.
    public nonisolated var cannotBeReached: Bool {
        get { catalogLock.withLock { _cannotBeReached } }
        set { catalogLock.withLock { _cannotBeReached = newValue } }
    }

    // MARK: - Holding an answer back

    private var holdsTheNextLookup = false
    private var releaseTheLookup: CheckedContinuation<Void, Never>?
    private var announceTheAsk: CheckedContinuation<Void, Never>?

    /// Makes the next catalogue lookup wait to be let go, so a test can look at
    /// the screen in the state between asking and being answered.
    public func holdTheNextLookup() {
        holdsTheNextLookup = true
    }

    /// Returns once the shop has been asked and is holding. Awaiting the screen's
    /// own work would run past the moment under test; yielding until a counter
    /// moves is a guess about scheduling rather than a wait.
    public func untilAsked() async {
        guard releaseTheLookup == nil else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            announceTheAsk = continuation
        }
    }

    public func answerNow() {
        releaseTheLookup?.resume()
        releaseTheLookup = nil
    }

    fileprivate func waitIfHolding() async {
        guard holdsTheNextLookup else { return }
        holdsTheNextLookup = false
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            releaseTheLookup = continuation
            announceTheAsk?.resume()
            announceTheAsk = nil
        }
    }

    public init(bag: Bag = Bag(), notices: Notices = Notices(), catalog: [Product] = []) {
        self.repository = FakeBagRepository(bag: bag, notices: notices)
        self._catalog = catalog
    }

    // MARK: - The real use cases, over this as their repository

    public var observeBag: ObserveBagUseCase { DefaultObserveBagUseCase(repository: self) }
    public var observeBagItemQuantity: ObserveBagItemQuantityUseCase {
        DefaultObserveBagItemQuantityUseCase(repository: self)
    }
    public var observeNotices: ObserveNoticesUseCase { DefaultObserveNoticesUseCase(repository: self) }
    public var setBagItemQuantity: SetBagItemQuantityUseCase { DefaultSetBagItemQuantityUseCase(repository: self) }
    public var bringUpToDate: BringBagUpToDateUseCase {
        DefaultBringBagUpToDateUseCase(repository: self, lookUpProducts: lookUpProducts)
    }
    public var acknowledge: AcknowledgeNoticesUseCase { DefaultAcknowledgeNoticesUseCase(repository: self) }
    public var addItemToBag: AddItemToBagUseCase { DefaultAddItemToBagUseCase(repository: self) }

    public nonisolated var lookUpProducts: LookUpProductsUseCase { Lookup(shop: self) }

    public func choose(_ item: BagItem) {
        addItemToBag(item)
    }

    // MARK: - BagRepository

    public var bag: Bag { repository.bag }
    public var bagPublisher: AnyPublisher<Bag, Never> { repository.bagPublisher }
    public var notices: Notices { repository.notices }
    public var noticesPublisher: AnyPublisher<Notices, Never> { repository.noticesPublisher }

    public func save(bag: Bag, notices: Notices) {
        repository.save(bag: bag, notices: notices)
    }

    // MARK: -

    nonisolated fileprivate func lookUp(_ ids: [ProductID]) -> [Product] {
        catalogLock.withLock {
            _lookups.append(ids)
            return _catalog.filter { ids.contains($0.id) }
        }
    }

    private struct Lookup: LookUpProductsUseCase {
        let shop: FakeShop
        func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
            await shop.waitIfHolding()
            guard !shop.cannotBeReached else { return .failure(.unavailable) }
            return .success(shop.lookUp(ids))
        }
    }
}
