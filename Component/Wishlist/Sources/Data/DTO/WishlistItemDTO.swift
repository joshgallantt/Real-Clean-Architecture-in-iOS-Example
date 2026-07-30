import Foundation
import Product
import Wishlist

/// Fowler, *PoEAA* (2002) — Data Transfer Object: the serialisation shape, kept out of the domain.
/// It maps at the boundary, so a wire format change stops here.
struct WishlistItemDTO: Codable, Sendable {
    let id: Int
    let dateAdded: Date

    init(from item: WishlistItem) {
        self.id = item.productId.rawValue
        self.dateAdded = item.dateAdded
    }

    func toDomain() -> WishlistItem {
        WishlistItem(productId: ProductID(rawValue: id), dateAdded: dateAdded)
    }
}
