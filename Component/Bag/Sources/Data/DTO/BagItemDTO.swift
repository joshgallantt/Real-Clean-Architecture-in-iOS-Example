import Foundation
import Bag

struct BagItemDTO: Codable, Sendable {
    let productId: Int
    let quantity: Int
    let lastKnownPrice: Double
    let dateAdded: Date

    init(from item: BagItem) {
        self.productId = item.productId
        self.quantity = item.quantity
        self.lastKnownPrice = item.lastKnownPrice
        self.dateAdded = item.dateAdded
    }

    func toDomain() -> BagItem {
        BagItem(productId: productId, quantity: quantity, lastKnownPrice: lastKnownPrice, dateAdded: dateAdded)
    }
}
