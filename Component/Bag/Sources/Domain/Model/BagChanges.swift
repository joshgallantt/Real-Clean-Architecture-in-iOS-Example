/// What the shop has done to the shopper's choices since they last looked, still waiting
/// to be mentioned.
///
/// Not part of the bag. A bag is what someone is going to buy; this is a list of things
/// to tell them, and one kind of entry — a product the shop can no longer supply — is
/// about something that has *left* the bag, so it could not live inside it without the
/// bag holding a reference to something outside itself.
///
/// It also changes for different reasons and at different times: the bag changes when the
/// shopper shops, this changes when the shop changes its mind and when the shopper says
/// they have seen it.
public struct BagChanges: Equatable, Sendable {
    public let all: [BagChange]

    public init(_ all: [BagChange] = []) {
        self.all = all
    }

    public var isEmpty: Bool { all.isEmpty }

    /// Products the shop can no longer supply. No longer in the bag.
    public var noLongerAvailable: [BagChange] { all.filter { !$0.isAboutAProductStillInTheBag } }

    /// Products still in the bag, at a price the shopper has not seen yet.
    public var priceMoves: [BagChange] { all.filter(\.isAboutAProductStillInTheBag) }

    public func about(productId: Int) -> [BagChange] {
        all.filter { $0.productId == productId }
    }

    /// The price this shopper last saw and dismissed, so a later move can be measured
    /// from what they know rather than from the last time anyone asked the shop.
    public func priceLastSeen(forProductId productId: Int) -> Double? {
        all.first { $0.productId == productId && $0.isAboutAProductStillInTheBag }?.priceLastSeen
    }

    /// The shopper has seen whatever happened to this product.
    public func acknowledging(productId: Int) -> BagChanges {
        BagChanges(all.filter { $0.productId != productId })
    }

    public func acknowledgingEverything() -> BagChanges {
        BagChanges()
    }
}
