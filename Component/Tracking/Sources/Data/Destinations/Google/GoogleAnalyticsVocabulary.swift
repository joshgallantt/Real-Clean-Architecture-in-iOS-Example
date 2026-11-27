import Tracking

/// Google's words for things — the event names and parameter keys GA4's Measurement Protocol and
/// the Firebase SDK share. Spelled once, here; the two mappers that speak Google ask for them
/// rather than typing them.
///
/// The one place in the app that knows a product added to a bag is called `add_to_cart`. Every
/// event and every property is answered for in a `switch` with no `default`, so a case added to
/// `EventName` or `PropertyKey` does not build until Google's word for it is written down.
struct GoogleAnalyticsVocabulary {
    /// The two events Google names for where something happened — in a list — rather than for what
    /// it was.
    enum ListEvent: String {
        case viewItemList = "view_item_list"
        case selectItem = "select_item"
    }

    enum Parameter: String {
        case screenName = "screen_name"
        case items
        case itemListId = "item_list_id"
        case itemListName = "item_list_name"
        case index
        case value
        case currency
    }

    enum Item: String {
        case id = "item_id"
        case name = "item_name"
        case category = "item_category"
        case price
        case quantity
    }

    /// GA4 drops a string longer than this rather than storing it.
    let maxTextLength = 100

    /// What Google calls an event.
    func eventName(for name: EventName) -> String {
        switch name {
        case .screenViewed: "screen_view"
        case .elementViewed: "view_content"
        case .elementSelected: "select_content"
        case .productViewed: "view_item"
        case .productAdded: "add_to_cart"
        case .productRemoved: "remove_from_cart"
        case .cartViewed: "view_cart"
        case .productAddedToWishlist: "add_to_wishlist"
        case .checkoutStarted: "begin_checkout"
        case .orderCompleted: "purchase"
        case .productsSearched: "search"
        case .signedIn: "login"
        case .signedUp: "sign_up"
        }
    }

    /// What Google calls a property.
    func parameterKey(for key: PropertyKey) -> String {
        switch key {
        case .element: "content_id"
        case .orderId: "transaction_id"
        case .query: "search_term"
        case .method: "method"
        }
    }
}
