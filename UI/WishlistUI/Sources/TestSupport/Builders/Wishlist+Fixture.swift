import Foundation
import Product
import Wishlist

extension Wishlist {
    /// A wishlist holding these, in this order. A wishlist keeps itself newest first, so each is
    /// saved a second before the one ahead of it.
    static func holding(_ ids: [ProductID]) -> Wishlist {
        Wishlist(items: ids.enumerated().map { index, id in
            WishlistItem(productId: id, dateAdded: Date(timeIntervalSinceReferenceDate: -Double(index)))
        })
    }
}
