import Foundation
import Product
import Wishlist

struct WishlistItemDTO: Codable, Sendable {
    /// Still `id` on the wire: this is what earlier builds wrote, and renaming a stored key
    /// would silently empty every wishlist already on disk.
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
