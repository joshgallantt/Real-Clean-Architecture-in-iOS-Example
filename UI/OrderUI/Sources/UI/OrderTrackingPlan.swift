/// The tracking plan for ordering: every screen and element this package reports, named once.
/// What a checkout or a purchase is made of is said by the button that starts it — see
/// `BuyNowButtonViewModel` and `CheckoutButtonViewModel`.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: the names are the ones a
/// report is read in, and changing one splits that report in two. They change here or nowhere.
public enum OrderTrackingPlan {
    public static let history = "order_history"
    public static let confirmation = "order_confirmation"

    static let buyNow = "buy_now"
    static let checkOut = "check_out"
    static let done = "done"
}
