import Combine
import Foundation
import Bag

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: a working repository rather
/// than a stub with canned answers, so the use cases under test genuinely read, apply and save.
///
/// Fowler, *PoEAA* (2002) — Repository.
final class InMemoryBagRepository: BagRepository {
    private let bagSubject: CurrentValueSubject<Bag, Never>
    private let changesSubject: CurrentValueSubject<BagChanges, Never>

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
