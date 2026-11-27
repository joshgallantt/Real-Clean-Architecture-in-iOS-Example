/// The tracking plan for the Account tab: its screen and every element it reports, named once.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: the names are the ones a
/// report is read in, and changing one splits that report in two. They change here or nowhere.
public enum AccountTrackingPlan {
    public static let screen = "account"

    static let logOut = "log_out"
    static let orders = "your_orders"
    static let settings = "settings"
}
