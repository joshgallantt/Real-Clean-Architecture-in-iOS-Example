import Foundation
import Bag

struct BagDTO: Codable, Sendable {
    let items: [BagItemDTO]
    let pendingChanges: [BagChangeDTO]

    init(from bag: Bag) {
        self.items = bag.items.map(BagItemDTO.init(from:))
        self.pendingChanges = bag.pendingChanges.map(BagChangeDTO.init(from:))
    }

    func toDomain() -> Bag {
        Bag(
            items: items.map { $0.toDomain() },
            pendingChanges: pendingChanges.compactMap { $0.toDomain() }
        )
    }
}

/// A change flattened for storage. A payload written by an older build, or one naming a
/// kind this build no longer has, decodes to nothing rather than failing the whole bag —
/// losing a warning is a small harm, losing the shopper's bag is not.
struct BagChangeDTO: Codable, Sendable {
    enum Kind: String, Codable, Sendable {
        case priceWentUp
        case priceWentDown
        case outOfStock
    }

    let kind: Kind
    let itemId: Int
    let from: Double?
    let to: Double?

    init(from change: BagChange) {
        self.itemId = change.itemId
        switch change {
        case .priceWentUp(_, let from, let to):
            self.kind = .priceWentUp
            self.from = from
            self.to = to
        case .priceWentDown(_, let from, let to):
            self.kind = .priceWentDown
            self.from = from
            self.to = to
        case .outOfStock:
            self.kind = .outOfStock
            self.from = nil
            self.to = nil
        }
    }

    func toDomain() -> BagChange? {
        switch kind {
        case .priceWentUp:
            guard let from, let to else { return nil }
            return .priceWentUp(itemId: itemId, from: from, to: to)
        case .priceWentDown:
            guard let from, let to else { return nil }
            return .priceWentDown(itemId: itemId, from: from, to: to)
        case .outOfStock:
            return .outOfStock(itemId: itemId)
        }
    }
}
