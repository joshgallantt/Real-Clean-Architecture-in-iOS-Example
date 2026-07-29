import Foundation
import Bag

struct BagItemDTO: Codable, Sendable {
    let id: Int
    let quantity: Int
    let lastKnownPrice: Double
    let dateAdded: Date

    init(from item: BagItem) {
        self.id = item.id
        self.quantity = item.quantity
        self.lastKnownPrice = item.lastKnownPrice
        self.dateAdded = item.dateAdded
    }

    func toDomain() -> BagItem {
        BagItem(id: id, quantity: quantity, lastKnownPrice: lastKnownPrice, dateAdded: dateAdded)
    }
}
