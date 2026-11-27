import Money
import Tracking

/// Fowler, *PoEAA* (2002), Ch. 18 — Mapper: an event in Firebase's words. The one place that knows
/// a product added to a bag is called `add_to_cart`.
///
/// Every event is answered for in a `switch` with no `default`, so a case added to `EventName`
/// does not build until Google's name for it is written down. Properties are key-value pairs: the
/// few Google has its own key for are renamed, and the rest go under the key they came with.
struct FirebaseEventMapper {
    /// Google Analytics drops a string longer than this rather than storing it.
    private let maxTextLength = 100

    func map(_ event: TrackingEvent) -> FirebaseEventDTO {
        FirebaseEventDTO(name: name(of: event), parameters: parameters(of: event), items: items(of: event))
    }

    /// Google names two events by where they happened: an item seen in a list, and one tapped there.
    private func name(of event: TrackingEvent) -> String {
        if event.context.listPosition != nil, !event.items.isEmpty {
            if event.name == .elementViewed { return "view_item_list" }
            if event.name == .elementSelected { return "select_item" }
        }
        return switch event.name {
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

    private func parameters(of event: TrackingEvent) -> [String: String] {
        var parameters: [String: String] = [:]
        for (key, value) in event.properties {
            parameters[parameterKey(for: key)] = text(value)
        }

        /// Only on the screen view. The SDK remembers the last screen it was told about and
        /// attaches it to every event after.
        if event.name == .screenViewed {
            parameters["screen_name"] = text(event.context.screen)
        }
        if let position = event.context.listPosition {
            parameters["item_list_id"] = text(position.list.id)
            parameters["item_list_name"] = text(position.list.name)
            if event.items.isEmpty {
                parameters["index"] = String(position.index)
            }
        }

        /// `value` and `currency` together or not at all: Google ignores a value it cannot price.
        if let value = event.value {
            parameters["value"] = "\(value.amount)"
            parameters["currency"] = value.currency.code
        }
        return parameters
    }

    private func parameterKey(for key: String) -> String {
        switch key {
        case "element": "content_id"
        case "order_id": "transaction_id"
        case "query": "search_term"
        default: key
        }
    }

    /// The list goes on the item as well as on the event, because Google reads it from the item first.
    private func items(of event: TrackingEvent) -> [[String: String]] {
        event.items.map { item in
            var fields = ["item_id": text(item.id), "item_name": text(item.name)]
            if case .product(let category, let price, let quantity) = item.details {
                fields["item_category"] = text(category)
                fields["price"] = "\(price.amount)"
                fields["quantity"] = String(quantity)
            }
            if let position = event.context.listPosition {
                fields["index"] = String(position.index)
                fields["item_list_id"] = text(position.list.id)
                fields["item_list_name"] = text(position.list.name)
            }
            return fields
        }
    }

    /// Cut to what Google keeps, which is the part a report shows anyway.
    private func text(_ value: String) -> String {
        String(value.prefix(maxTextLength))
    }
}
