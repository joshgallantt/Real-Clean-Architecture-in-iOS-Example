import Bag
import Money
import Product
import Tracking

/// The tracking plan for the bag: its screen, its elements and its lists, named once. What a change
/// to the bag reports, and about which lines, is said where it happens — see `BagScreenViewModel`.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: the names are the ones a
/// report is read in, and changing one splits that report in two. They change here or nowhere.
public enum BagTrackingPlan {
    public static let screen = "bag"

    static let bagLines = TrackingContext.List(id: "bag", name: "Bag")

    static let line = "bag_line"
    static let noticeLine = "notice_line"
    static let quantityUp = "quantity_up"
    static let quantityDown = "quantity_down"
    static let swipeRemove = "remove"
    static let removeChanged = "remove_from_bag"
    static let removeAll = "remove_all"

    /// One list per kind of notice, because "sold out" and "price went up" are read for different
    /// reasons and a report that pooled them could not say which one sent a shopper anywhere.
    static func notices(_ kind: Notice.Kind) -> TrackingContext.List {
        switch kind {
        case .outOfStock: TrackingContext.List(id: "bag_notices_out_of_stock", name: "Sold Out")
        case .onlySomeLeft: TrackingContext.List(id: "bag_notices_only_some_left", name: "Nearly Gone")
        case .priceWentUp: TrackingContext.List(id: "bag_notices_price_went_up", name: "Price Went Up")
        case .priceWentDown: TrackingContext.List(id: "bag_notices_price_went_down", name: "Price Went Down")
        }
    }

    static func acceptAll(_ kind: Notice.Kind) -> String {
        "accept_all_" + String(notices(kind).id.dropFirst("bag_notices_".count))
    }
}
