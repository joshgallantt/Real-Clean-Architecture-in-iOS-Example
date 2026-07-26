import Foundation
import Bag

struct BagItemDTO: Codable, Sendable {
    let id: Int
    let quantity: Int
    let dateAdded: Date

    init(from item: BagItem) {
        self.id = item.id
        self.quantity = item.quantity
        self.dateAdded = item.dateAdded
    }

    func toDomain() -> BagItem {
        BagItem(id: id, quantity: quantity, dateAdded: dateAdded)
    }
}
