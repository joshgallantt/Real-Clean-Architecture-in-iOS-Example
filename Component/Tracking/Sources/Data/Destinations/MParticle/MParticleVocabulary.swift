import Tracking

/// mParticle's words for things, spelled once. They are not Google's: where Google has
/// `add_to_cart` and `begin_checkout` as event names, mParticle has one commerce event and an
/// action on it, and it has no word at all for looking at a cart.
///
/// Every event and every property is answered for in a `switch` with no `default`, so a case added
/// to `EventName` or `PropertyKey` does not build until someone has said which shape mParticle
/// takes it in, or where it keeps it.
struct MParticleVocabulary {
    enum EventType: String {
        case screenView = "screen_view"
        case commerce = "commerce_event"
        case custom = "custom_event"
    }

    enum Field: String {
        case eventType = "event_type"
        case data
        case screenName = "screen_name"
        case eventName = "event_name"
        case customEventType = "custom_event_type"
        case customAttributes = "custom_attributes"
        case productAction = "product_action"
        case action
        case products
        case transactionId = "transaction_id"
        case totalAmount = "total_amount"
        case currencyCode = "currency_code"
        case productImpressions = "product_impressions"
        case impressionList = "product_impression_list"
        case listId = "list_id"
    }

    enum ProductField: String {
        case id
        case name
        case category
        case price
        case quantity
        case position
    }

    /// What was done to the products of a commerce event.
    enum ProductAction: String {
        case viewDetail = "view_detail"
        case addToCart = "add_to_cart"
        case removeFromCart = "remove_from_cart"
        case addToWishlist = "add_to_wishlist"
        case checkout
        case purchase
        case click
    }

    /// mParticle sorts custom events into a handful of kinds.
    enum CustomEventType: String {
        case search
        case navigation
        case userPreference = "user_preference"
        case other
    }

    /// The shape mParticle takes an event in. Cases, not an optional product action: having no
    /// action for looking at a cart is an answer too, and it comes with which kind of custom event
    /// that is instead.
    enum EventShape: Equatable {
        case screenView
        case commerce(ProductAction)
        case custom(CustomEventType)
    }

    /// Where mParticle keeps a property: with the custom attributes under its own key, or in a field
    /// the product action has for it.
    enum PropertyPlace: Equatable {
        case customAttribute
        case actionField(Field)
    }

    /// Which shape an event goes to mParticle in.
    func shape(of name: EventName) -> EventShape {
        switch name {
        case .screenViewed: .screenView
        case .elementViewed: .custom(.other)
        case .elementSelected: .custom(.navigation)
        case .productViewed: .commerce(.viewDetail)
        case .productAdded: .commerce(.addToCart)
        case .productRemoved: .commerce(.removeFromCart)
        case .cartViewed: .custom(.other)
        case .productAddedToWishlist: .commerce(.addToWishlist)
        case .checkoutStarted: .commerce(.checkout)
        case .orderCompleted: .commerce(.purchase)
        case .productsSearched: .custom(.search)
        case .signedIn, .signedUp: .custom(.userPreference)
        }
    }

    /// Which place mParticle has for a property.
    func place(of key: PropertyKey) -> PropertyPlace {
        switch key {
        case .element: .customAttribute
        // On a purchase the order id is the transaction, not something said about it.
        case .orderId: .actionField(.transactionId)
        case .query: .customAttribute
        case .method: .customAttribute
        }
    }
}
