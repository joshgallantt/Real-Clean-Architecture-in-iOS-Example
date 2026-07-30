import Foundation
import Bag
import Money
import Product

/// Fowler, *PoEAA* (2002), Ch. 15 — Data Transfer Object: the serialisation shape, kept out of the
/// domain. It maps at the boundary, so a wire format change stops here.
struct BagDTO: Codable, Sendable {
    let items: [BagItemDTO]
    let notices: [NoticeDTO]

    /// The key on disk stays what it has always been. Renaming a property in Swift is not a reason
    /// for a bag written by an older build to come back empty.
    enum CodingKeys: String, CodingKey {
        case items
        case notices = "pendingChanges"
    }

    init(bag: Bag, notices: Notices) {
        self.items = bag.items.map(BagItemDTO.init(from:))
        self.notices = notices.all.map(NoticeDTO.init(from:))
    }

    func toDomain() -> (bag: Bag, notices: Notices) {
        (
            Bag(items: items.map { $0.toDomain() }),
            Notices(notices.compactMap { $0.toDomain() })
        )
    }
}

/// Fowler, *PoEAA* (2002), Ch. 15 — Data Transfer Object: the serialisation shape, kept out of the
/// domain. It maps at the boundary, so a wire format change stops here.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: a payload naming a kind
/// this build no longer has stops at the boundary rather than failing the whole bag. Losing a
/// notice is a small harm; losing the shopper's bag is not.
struct NoticeDTO: Codable, Sendable {
    /// Its own list, spelled out rather than shared with `Notice.Kind`. These names are on disk in
    /// bags this app has already written, so they are a format to be kept rather than a spelling to
    /// be refactored, and `storedKind(of:)` below is where the two are made to agree.
    enum Kind: String, Codable, Sendable {
        case priceWentUp
        case priceWentDown
        case onlySomeLeft
        case outOfStock
        case discontinued

        /// What "it has gone" was called before the two ways of going were told apart. A bag
        /// written by an older build still reads, and its notice becomes the recoverable one —
        /// offering to tell a shopper about something already back is a smaller wrong than
        /// promising word about something that will never return.
        static let legacyGone = "noLongerAvailable"
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

    init(from notice: Notice) {
        self.kind = Self.storedKind(of: notice.kind).rawValue
        self.productId = notice.productId.rawValue

        switch notice {
        case .priceWentUp(_, let from, let to), .priceWentDown(_, let from, let to):
            self.fromMinorUnits = from.minorUnits
            self.toMinorUnits = to.minorUnits
            self.currencyCode = to.currency.code
            self.available = nil

        case .onlySomeLeft(_, let available):
            self.fromMinorUnits = nil
            self.toMinorUnits = nil
            self.currencyCode = nil
            self.available = available

        case .outOfStock, .discontinued:
            self.fromMinorUnits = nil
            self.toMinorUnits = nil
            self.currencyCode = nil
            self.available = nil
        }
    }

    func toDomain() -> Notice? {
        let id = ProductID(rawValue: productId)

        if kind == Kind.legacyGone { return .outOfStock(productId: id) }

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
        case .outOfStock:
            return .outOfStock(productId: id)
        case .discontinued:
            return .discontinued(productId: id)
        }
    }

    /// The one place the domain's list of notices and the one on disk are made to agree. A sixth
    /// kind of notice fails to compile here until it has been given a name to be stored under.
    private static func storedKind(of kind: Notice.Kind) -> Kind {
        switch kind {
        case .priceWentUp: .priceWentUp
        case .priceWentDown: .priceWentDown
        case .onlySomeLeft: .onlySomeLeft
        case .outOfStock: .outOfStock
        case .discontinued: .discontinued
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
