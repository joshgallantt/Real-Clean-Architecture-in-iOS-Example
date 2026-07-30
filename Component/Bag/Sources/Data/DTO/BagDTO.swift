import Foundation
import Bag
import Money
import Product

/// Fowler, *PoEAA* (2002) — Data Transfer Object: the serialisation shape, kept out of the domain.
/// It maps at the boundary, so a wire format change stops here.
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

/// Fowler, *PoEAA* (2002) — Data Transfer Object: the serialisation shape, kept out of the domain.
/// It maps at the boundary, so a wire format change stops here.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: a payload naming a kind
/// this build no longer has stops at the boundary rather than failing the whole bag. Losing a
/// notice is a small harm; losing the shopper's bag is not.
struct BagChangeDTO: Codable, Sendable {
    enum Kind: String, Codable, Sendable {
        case priceWentUp
        case priceWentDown
        case onlySomeLeft
        case noLongerAvailable
    }

    /// Held as its raw form, not as `Kind`. Decoding straight into the enum throws on a kind this
    /// build does not have, and one throw anywhere in the payload costs the shopper their whole
    /// bag. Read as a string, an unrecognised notice is simply a notice that cannot be shown.
    let kind: String
    let productId: Int
    let fromMinorUnits: Int?
    let toMinorUnits: Int?
    let currencyCode: String?
    let available: Int?

    init(from change: BagChange) {
        self.productId = change.productId.rawValue

        switch change {
        case .priceWentUp(_, let from, let to):
            self.kind = Kind.priceWentUp.rawValue
            self.fromMinorUnits = from.minorUnits
            self.toMinorUnits = to.minorUnits
            self.currencyCode = to.currency.code
            self.available = nil
        case .priceWentDown(_, let from, let to):
            self.kind = Kind.priceWentDown.rawValue
            self.fromMinorUnits = from.minorUnits
            self.toMinorUnits = to.minorUnits
            self.currencyCode = to.currency.code
            self.available = nil
        case .onlySomeLeft(_, let available):
            self.kind = Kind.onlySomeLeft.rawValue
            self.fromMinorUnits = nil
            self.toMinorUnits = nil
            self.currencyCode = nil
            self.available = available
        case .noLongerAvailable:
            self.kind = Kind.noLongerAvailable.rawValue
            self.fromMinorUnits = nil
            self.toMinorUnits = nil
            self.currencyCode = nil
            self.available = nil
        }
    }

    func toDomain() -> BagChange? {
        let id = ProductID(rawValue: productId)

        switch Kind(rawValue: kind) {
        case .none:
            return nil
        case .priceWentUp:
            guard let prices = priceMove() else { return nil }
            return .priceWentUp(productId: id, from: prices.from, to: prices.to)
        case .priceWentDown:
            guard let prices = priceMove() else { return nil }
            return .priceWentDown(productId: id, from: prices.from, to: prices.to)
        case .onlySomeLeft:
            guard let available else { return nil }
            return .onlySomeLeft(productId: id, available: available)
        case .noLongerAvailable:
            return .noLongerAvailable(productId: id)
        }
    }

    private func priceMove() -> (from: Money, to: Money)? {
        guard let fromMinorUnits, let toMinorUnits, let currencyCode else { return nil }
        let currency = Currency(code: currencyCode, minorUnitsPerMajor: 100)
        return (
            Money(minorUnits: fromMinorUnits, currency: currency),
            Money(minorUnits: toMinorUnits, currency: currency)
        )
    }
}
