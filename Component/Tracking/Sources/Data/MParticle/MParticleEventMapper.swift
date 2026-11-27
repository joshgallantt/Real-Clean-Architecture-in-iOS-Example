import Money
import Tracking

/// Fowler, *PoEAA* (2002), Ch. 18 — Mapper: an event in mParticle's shape. It takes only what
/// mParticle uses: an item that is not a product has no place in a commerce event.
///
/// Every event is answered for in a `switch` with no `default`, so a case added to `EventName`
/// does not build until someone has said which kind mParticle takes it as. Properties are
/// key-value pairs and go with the attributes under the key they came with.
struct MParticleEventMapper {
    func map(_ event: TrackingEvent) -> MParticleEventDTO {
        let kind = kind(of: event)
        return MParticleEventDTO(
            kind: kind,
            name: kind == .screenView ? event.context.screen : event.name.rawValue,
            attributes: attributes(of: event),
            products: products(of: event)
        )
    }

    /// An item seen in a list is a product impression, and a tap on it a click, whatever seeing or
    /// tapping anything else is.
    private func kind(of event: TrackingEvent) -> MParticleEventDTO.Kind {
        if event.context.listPosition != nil, !event.items.isEmpty {
            if event.name == .elementViewed { return .commerce(action: "impression") }
            if event.name == .elementSelected { return .commerce(action: "click") }
        }
        return switch event.name {
        case .screenViewed: .screenView
        case .elementViewed: .custom(type: "other")
        case .elementSelected: .custom(type: "navigation")
        case .productViewed: .commerce(action: "view_detail")
        case .productAdded: .commerce(action: "add_to_cart")
        case .productRemoved: .commerce(action: "remove_from_cart")
        // mParticle has no word for looking at a cart.
        case .cartViewed: .custom(type: "other")
        case .productAddedToWishlist: .commerce(action: "add_to_wishlist")
        case .checkoutStarted: .commerce(action: "checkout")
        case .orderCompleted: .commerce(action: "purchase")
        case .productsSearched: .custom(type: "search")
        case .signedIn, .signedUp: .custom(type: "user_preference")
        }
    }

    /// mParticle's attributes are all text. Where the event happened goes with them.
    private func attributes(of event: TrackingEvent) -> [String: String] {
        var attributes = event.properties
        attributes["screen_name"] = event.context.screen
        if let position = event.context.listPosition {
            attributes["list_id"] = position.list.id
            attributes["list_name"] = position.list.name
        }
        if let value = event.value {
            attributes["total_amount"] = "\(value.amount)"
            attributes["currency_code"] = value.currency.code
        }
        return attributes
    }

    private func products(of event: TrackingEvent) -> [[String: String]] {
        event.items.compactMap { item in
            guard case .product(let category, let price, let quantity) = item.details else { return nil }
            var fields = [
                "id": item.id,
                "name": item.name,
                "category": category,
                "price": "\(price.amount)",
                "quantity": String(quantity)
            ]
            if let position = event.context.listPosition {
                fields["position"] = String(position.index)
            }
            return fields
        }
    }
}
