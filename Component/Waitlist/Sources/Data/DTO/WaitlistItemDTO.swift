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
