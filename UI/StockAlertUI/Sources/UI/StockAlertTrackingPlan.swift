import Tracking

/// The tracking plan for the shopper's stock alerts, on the tab that shows a row of them and on the
/// full screen that row opens: the screen, what can be touched, and the list itself — named once.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: these names are what a
/// report is read in, and changing one splits that report in two. They change here or nowhere. The
/// list says `wishlist_` because it is reported from the wishlist tab, whichever package draws it.
public enum StockAlertTrackingPlan {
    /// The list has the same id on the tab and on its own screen. It is the same list whether a
    /// shopper is looking at a handful of it in a row or all of it in a grid; the screen is what
    /// tells the two apart, and every event already says which screen it was on.
    static let list = TrackingContext.List(id: "wishlist_stock_alerts", name: "Stock Alerts")

    /// The list's own screen is named for the list.
    public static let screen = list.id

    static let viewAll = "view_all"
    static let clear = "clear"

    /// What a list-wide button is about: the list itself.
    static let listItem = TrackedItem.content(id: list.id, name: list.name)
}
