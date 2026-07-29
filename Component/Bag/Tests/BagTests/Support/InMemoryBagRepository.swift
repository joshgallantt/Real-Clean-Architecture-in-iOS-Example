import Combine
import Foundation
import Bag

/// A working bag repository, not a stub with canned answers: it keeps what it is given
/// and hands it back. The use cases under test genuinely read, apply and save.
@MainActor
final class InMemoryBagRepository: BagRepository {
    private let bagSubject: CurrentValueSubject<Bag, Never>
    private let changesSubject: CurrentValueSubject<BagChanges, Never>

    /// Every save, in order, so a test can see what a use case decided to keep rather
    /// than only where things ended up.
    private(set) var saved: [(bag: Bag, changes: BagChanges)] = []

    init(_ bag: Bag = Bag(), changes: BagChanges = BagChanges()) {
        self.bagSubject = CurrentValueSubject(bag)
        self.changesSubject = CurrentValueSubject(changes)
    }

    var bag: Bag { bagSubject.value }

    var bagPublisher: AnyPublisher<Bag, Never> { bagSubject.eraseToAnyPublisher() }

    var changes: BagChanges { changesSubject.value }

    var changesPublisher: AnyPublisher<BagChanges, Never> { changesSubject.eraseToAnyPublisher() }

    func save(bag: Bag, changes: BagChanges) {
        saved.append((bag, changes))
        bagSubject.value = bag
        changesSubject.value = changes
    }
}
