import Foundation
import Bag

struct BagDTO: Codable, Sendable {
    let items: [BagItemDTO]
    let pendingChanges: [BagChangeDTO]

    init(bag: Bag, changes: BagChanges) {
        self.items = bag.items.map(BagItemDTO.init(from:))
        self.pendingChanges = changes.all.map(BagChangeDTO.init(from:))
    }

    func toDomain() -> (bag: Bag, changes: BagChanges) {
        (
            Bag(items: items.map { $0.toDomain() }),
            BagChanges(pendingChanges.compactMap { $0.toDomain() })
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
        case noLongerAvailable
    }

    let kind: Kind
    let productId: Int
    let from: Double?
    let to: Double?

    init(from change: BagChange) {
        self.productId = change.productId
        switch change {
        case .priceWentUp(_, let from, let to):
            self.kind = .priceWentUp
            self.from = from
            self.to = to
        case .priceWentDown(_, let from, let to):
            self.kind = .priceWentDown
            self.from = from
            self.to = to
        case .noLongerAvailable:
            self.kind = .noLongerAvailable
            self.from = nil
            self.to = nil
        }
    }

    func toDomain() -> BagChange? {
        switch kind {
        case .priceWentUp:
            guard let from, let to else { return nil }
            return .priceWentUp(productId: productId, from: from, to: to)
        case .priceWentDown:
            guard let from, let to else { return nil }
            return .priceWentDown(productId: productId, from: from, to: to)
        case .noLongerAvailable:
            return .noLongerAvailable(productId: productId)
        }
    }
}
