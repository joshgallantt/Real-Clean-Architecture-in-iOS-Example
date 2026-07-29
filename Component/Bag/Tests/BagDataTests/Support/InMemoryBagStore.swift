import Foundation
import Bag
@testable import BagData

final class InMemoryBagStore: BagStore, @unchecked Sendable {
    private let lock = NSLock()
    private var bags: [String: Bag] = [:]
    private var _writes: [Bag] = []

    /// Every write in the order it landed, so ordering guarantees can be asserted
    /// rather than inferred from the final state.
    var writes: [Bag] { lock.withLock { _writes } }

    init(seeded: [String: Bag] = [:]) {
        self.bags = seeded
    }

    func getBag(forUserKey userKey: String) -> Bag {
        lock.withLock { bags[userKey] ?? Bag() }
    }

    func setBag(_ bag: Bag, forUserKey userKey: String) async {
        lock.withLock {
            bags[userKey] = bag
            _writes.append(bag)
        }
    }
}
