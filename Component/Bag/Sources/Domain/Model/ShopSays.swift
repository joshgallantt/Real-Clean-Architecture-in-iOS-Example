import Money
import Product

/// What the shop currently says about one product the bag holds: what it costs, and whether
/// it can be supplied.
///
/// The bag's side of its boundary with the catalog, and deliberately not `Product`. A bag
/// reasons about exactly these three things; handed a whole product it would also be handed
/// a title, a description, a brand, a rating, a thumbnail and a set of images, and would
/// then be a context that recompiles whenever any of them changes. Declaring what it needs
/// is the same move as declaring its own repository protocol — the bag says what it wants,
/// and whoever has a catalog to hand supplies it.
///
/// Identity and availability come from the catalog because they mean the same thing in both
/// places. Copying them would be inventing a second answer to a question the shop has
/// already answered.
public struct ShopSays: Equatable, Sendable {
    public let productId: ProductID
    public let price: Money
    public let availability: Availability

    public init(productId: ProductID, price: Money, availability: Availability) {
        self.productId = productId
        self.price = price
        self.availability = availability
    }
}
