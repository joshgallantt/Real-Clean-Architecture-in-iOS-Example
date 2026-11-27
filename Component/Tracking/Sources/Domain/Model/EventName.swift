/// What an event is called: the conventional vocabulary of a shop — what any screen reports, and
/// the steps every shop reports and every analytics tool has a word for.
///
/// One closed list, so each vendor's mapper is a `switch` the compiler checks: a new
/// event here does not build until every vendor's mapper has said what it calls it. There is no case
/// for "anything else", because an event nobody has a word for is one no report can count.
///
/// The raw value is the title a person reads — a thing and what became of it — spelled here and
/// nowhere else.
public enum EventName: String, CaseIterable, Sendable {
    // What any screen reports.
    case screenViewed = "Screen Viewed"
    case elementViewed = "Element Viewed"
    case elementSelected = "Element Selected"

    // The steps through a shop.
    case productViewed = "Product Viewed"
    case productAdded = "Product Added"
    case productRemoved = "Product Removed"
    case cartViewed = "Cart Viewed"
    case productAddedToWishlist = "Product Added to Wishlist"
    case checkoutStarted = "Checkout Started"
    case orderCompleted = "Order Completed"
    case productsSearched = "Products Searched"
    case signedIn = "Signed In"
    case signedUp = "Signed Up"
}
