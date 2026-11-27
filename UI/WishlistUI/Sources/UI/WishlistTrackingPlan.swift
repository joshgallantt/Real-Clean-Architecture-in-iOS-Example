import Tracking

/// The tracking plan for the wishlist tab and the three full lists it opens: their screens, what
/// can be touched on them, and the lists themselves — named once.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: these names are what a
/// report is read in, and changing one splits that report in two. They change here or nowhere.
///
/// A list has the same id on the tab and on its own screen. My Faves is My Faves whether a shopper
/// is looking at five of them in a row or all of them in a grid; the screen is what tells the two
/// apart, and every event already says which screen it was on.
public enum WishlistTrackingPlan {
    public static let screen = "wishlist"
    public static let favesScreen = "wishlist_faves"
    public static let waitlistScreen = "wishlist_waitlist"
    public static let backInStockScreen = "wishlist_back_in_stock"

    public static let faves = TrackingContext.List(id: "wishlist_faves", name: "My Faves")
    public static let waitlist = TrackingContext.List(id: "wishlist_waitlist", name: "Waitlist")
    public static let backInStock = TrackingContext.List(id: "wishlist_back_in_stock", name: "Back in Stock")

    static let viewAll = "view_all"
    static let clear = "clear"
    static let signIn = "sign_in"

    /// What a list-wide button is about: the list itself.
    static func item(_ list: TrackingContext.List) -> TrackedItem {
        .content(id: list.id, name: list.name)
    }
}
