import Foundation
import Product
import StockAlert

/// Fowler, *PoEAA* (2002) — Data Transfer Object: the serialisation shape, kept out of the domain.
/// It maps at the boundary, so a wire format change stops here.
struct StockAlertDTO: Codable, Sendable {
    let id: Int
    let dateAdded: Date

    init(from item: StockAlert) {
        self.id = item.productId.rawValue
        self.dateAdded = item.dateAdded
    }

    func toDomain() -> StockAlert {
        StockAlert(productId: ProductID(rawValue: id), dateAdded: dateAdded)
    }
}
