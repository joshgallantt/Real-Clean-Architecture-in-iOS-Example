import Foundation
import Bag
@testable import BagData

final class InMemoryBagStore: BagStore, @unchecked Sendable {
    private let lock = NSLock()
    private var bags: [String: (bag: Bag, changes: BagChanges)] = [:]
    private var _writes: [(bag: Bag, changes: BagChanges)] = []

    /// Every write in the order it landed, so ordering guarantees can be asserted
    /// rather than inferred from the final state.
    var writes: [(bag: Bag, changes: BagChanges)] { lock.withLock { _writes } }

    init(seeded: [String: (bag: Bag, changes: BagChanges)] = [:]) {
        self.bags = seeded
    }

    func getBag(forUserKey userKey: String) -> (bag: Bag, changes: BagChanges) {
        lock.withLock { bags[userKey] ?? (Bag(), BagChanges()) }
    }

    func setBag(_ bag: Bag, changes: BagChanges, forUserKey userKey: String) async {
        lock.withLock {
            bags[userKey] = (bag, changes)
            _writes.append((bag, changes))
        }
    }
}
