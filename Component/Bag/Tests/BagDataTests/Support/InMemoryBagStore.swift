import Foundation
import Bag
import Money
import Product
@testable import BagData

final class InMemoryBagStore: BagStore, @unchecked Sendable {
    private let lock = NSLock()
    private var bags: [BagOwner: (bag: Bag, changes: BagChanges)] = [:]
    private var _writes: [(bag: Bag, changes: BagChanges)] = []

    /// Every write in the order it landed, so ordering guarantees can be asserted
    /// rather than inferred from the final state.
    var writes: [(bag: Bag, changes: BagChanges)] { lock.withLock { _writes } }

    init(seeded: [BagOwner: (bag: Bag, changes: BagChanges)] = [:]) {
        self.bags = seeded
    }

    func getBag(for owner: BagOwner) -> (bag: Bag, changes: BagChanges) {
        lock.withLock { bags[owner] ?? (Bag(), BagChanges()) }
    }

    func setBag(_ bag: Bag, changes: BagChanges, for owner: BagOwner) async {
        lock.withLock {
            bags[owner] = (bag, changes)
            _writes.append((bag, changes))
        }
    }
}

// MARK: - Fixtures

func usd(_ amount: Decimal) -> Money {
    Money(amount: amount, currency: .usd)
}

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}

func item(_ id: Int, quantity: Int = 1, price: Decimal, addedAt: Date = Date()) -> BagItem {
    BagItem(productId: pid(id), quantity: quantity, lastKnownPrice: usd(price), dateAdded: addedAt)
}
