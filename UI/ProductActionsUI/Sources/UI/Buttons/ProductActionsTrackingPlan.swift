/// The tracking plan for what a shopper can do to a product: every element these buttons report,
/// named once. A heart on Home and a heart in the bag are the same element on two screens, so the
/// name lives with the button and the screen arrives from whoever drew it.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: the names are the ones a
/// report is read in, and changing one splits that report in two. They change here or nowhere.
enum ProductActionsTrackingPlan {
    /// A toggle, because which way it went is the point: saving and unsaving are two decisions.
    static func wishlist(isOn: Bool) -> String { isOn ? "wishlist_on" : "wishlist_off" }

    static func stockAlert(isOn: Bool) -> String { isOn ? "stock_alert_on" : "stock_alert_off" }

    static let removeStockAlert = "remove_stock_alert"
    static let addToBag = "add_to_bag"

    /// The View on the snackbar that follows adding to the bag.
    static let viewBag = "snackbar_view_bag"
}
