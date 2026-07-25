import Foundation
import Wishlist

struct WishlistItemDTO: Codable {
    let id: Int
    let dateAdded: Date

    init(from item: WishlistItem) {
        self.id = item.id
        self.dateAdded = item.dateAdded
    }

    func toDomain() -> WishlistItem {
        WishlistItem(id: id, dateAdded: dateAdded)
    }
}
