import Tracking

/// The tracking plan for the bag: its screen, its elements and its lists, named once. What a change
/// to the bag reports, and about which lines, is said where it happens — see `BagScreenViewModel`.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: the names are the ones a
/// report is read in, and changing one splits that report in two. They change here or nowhere.
public enum BagTrackingPlan {
    public static let screen = "bag"

    static let bagLines = TrackingContext.List(id: "bag", name: "Bag")

    /// One list for everything that changed since the shopper last viewed the bag. The rows in it
    /// are told apart by the product each is about, which is what a report asks of them.
    static let changes = TrackingContext.List(id: "bag_changes", name: "Changes Since You Last Viewed")

    static let line = "bag_line"
    static let changeLine = "bag_change_line"
    static let quantityUp = "quantity_up"
    static let quantityDown = "quantity_down"
    static let swipeRemove = "remove"
    static let removeAll = "remove_all"
}
