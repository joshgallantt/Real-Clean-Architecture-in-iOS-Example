import Product

/// Evans, *Domain-Driven Design* (2003), Ch. 5 — Value Objects: a bag held against what the shop
/// says now. What was asked and what was answered, the bag as it truthfully is, and everything that
/// makes it differ from the bag that was kept.
///
/// It keeps what was asked and answered beside the result, so the same answer can be held against
/// the bag again once the shopper has changed it — without going back to the shop to be told what
/// it has already said.
public struct CheckedBag: Equatable, Sendable {
    /// Today's prices, no more of anything than the shop has, and no line the shop cannot supply.
    public let bag: Bag

    /// What changed, in the order the kept bag held its lines.
    public let changes: [BagChange]

    /// What the shop said about the products it was asked about. Something sold out is described;
    /// something it has stopped selling is not.
    public let products: [Product]

    public let asked: Set<ProductID>

    public init(bag: Bag, changes: [BagChange], products: [Product], asked: Set<ProductID>) {
        self.bag = bag
        self.changes = changes
        self.products = products
        self.asked = asked
    }
}
