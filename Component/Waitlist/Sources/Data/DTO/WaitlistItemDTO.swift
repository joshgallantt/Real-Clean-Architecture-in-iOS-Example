import Foundation
import Product
import Waitlist

/// Fowler, *PoEAA* (2002) — Data Transfer Object: the serialisation shape, kept out of the domain.
/// It maps at the boundary, so a wire format change stops here.
struct WaitlistItemDTO: Codable, Sendable {
    let id: Int
    let dateAdded: Date

    init(from item: WaitlistItem) {
        self.id = item.productId.rawValue
        self.dateAdded = item.dateAdded
    }

    func toDomain() -> WaitlistItem {
        WaitlistItem(productId: ProductID(rawValue: id), dateAdded: dateAdded)
    }
}

/// The shape the waitlist was written in when it was called stock alerts. Read once, to carry a
/// shopper's list forward, and never written.
struct LegacyStockAlertDTO: Decodable, Sendable {
    let productId: Int
    let dateAsked: Date

    func toDomain() -> WaitlistItem {
        WaitlistItem(productId: ProductID(rawValue: productId), dateAdded: dateAsked)
    }
}
