import Foundation
import Money
import Tracking

/// Fowler, *PoEAA* (2002), Ch. 18 — Mapper: an event, in mParticle's Events API shape. Every event
/// has an `event_type`; a step through the shop is a commerce event with a product action, an item
/// seen in a list is a product impression, and anything mParticle has no action for is a custom
/// event under the event's own title. Which of those an event is, `MParticleVocabulary` says.
///
/// It takes only what mParticle uses. An item that is not a product has no place in a commerce
/// event, so it goes as custom attributes or not at all.
struct MParticleEventMapper {
    private typealias Words = MParticleVocabulary

    private let words = Words()

    func payload(for event: TrackingEvent) -> JSONValue {
        if event.name == .elementViewed, let item = event.items.first, case .inList(let list, let index) = event.context.placement {
            return commerce(event, [
                Words.Field.productImpressions.rawValue: .array([.object([
                    Words.Field.impressionList.rawValue: .string(list.name),
                    Words.Field.products.rawValue: .array([product(item, position: index)])
                ])])
            ])
        }
        if event.name == .elementSelected, let item = event.items.first, case .inList(_, let index) = event.context.placement {
            return commerce(event, [
                Words.Field.productAction.rawValue: .object([
                    Words.Field.action.rawValue: .string(Words.ProductAction.click.rawValue),
                    Words.Field.products.rawValue: .array([product(item, position: index)])
                ])
            ])
        }
        switch words.shape(of: event.name) {
        case .screenView:
            return envelope(.screenView, [Words.Field.screenName.rawValue: .string(event.context.screen)])
        case .commerce(let action):
            return commerce(event, [Words.Field.productAction.rawValue: .object(productAction(action, for: event))])
        case .custom(let type):
            return envelope(.custom, [
                Words.Field.eventName.rawValue: .string(event.name.rawValue),
                Words.Field.customEventType.rawValue: .string(type.rawValue),
                Words.Field.customAttributes.rawValue: .object(attributes(of: event))
            ])
        }
    }

    private func envelope(_ type: Words.EventType, _ data: [String: JSONValue]) -> JSONValue {
        .object([Words.Field.eventType.rawValue: .string(type.rawValue), Words.Field.data.rawValue: .object(data)])
    }

    private func commerce(_ event: TrackingEvent, _ fields: [String: JSONValue]) -> JSONValue {
        var data = fields
        data[Words.Field.customAttributes.rawValue] = .object(attributes(of: event))
        if let worth = Worth(of: event.items) {
            data[Words.Field.currencyCode.rawValue] = .string(worth.currency)
        }
        return envelope(.commerce, data)
    }

    private func productAction(_ action: Words.ProductAction, for event: TrackingEvent) -> [String: JSONValue] {
        var fields: [String: JSONValue] = [
            Words.Field.action.rawValue: .string(action.rawValue),
            Words.Field.products.rawValue: .array(event.items.map { .object(self.fields(of: $0)) })
        ]
        for (key, value) in event.properties {
            if case .actionField(let field) = words.place(of: key) {
                fields[field.rawValue] = .string(value)
            }
        }
        if let worth = Worth(of: event.items) {
            fields[Words.Field.totalAmount.rawValue] = .number(worth.amount)
        }
        return fields
    }

    private func product(_ item: TrackedItem, position: Int) -> JSONValue {
        var fields = fields(of: item)
        fields[Words.ProductField.position.rawValue] = .integer(position)
        return .object(fields)
    }

    private func fields(of item: TrackedItem) -> [String: JSONValue] {
        var fields: [String: JSONValue] = [
            Words.ProductField.id.rawValue: .string(item.id),
            Words.ProductField.name.rawValue: .string(item.name)
        ]
        if case .product(let category, let price, let quantity) = item.details {
            fields[Words.ProductField.category.rawValue] = .string(category)
            fields[Words.ProductField.price.rawValue] = .number(price.amount)
            fields[Words.ProductField.quantity.rawValue] = .integer(quantity)
        }
        return fields
    }

    /// mParticle's custom attributes are all text. Where the event happened goes with them, since
    /// only a screen view has a field of its own for it. A property the product action has a field
    /// for — the order id, on a purchase — is left out.
    private func attributes(of event: TrackingEvent) -> [String: JSONValue] {
        var attributes: [String: JSONValue] = [Words.Field.screenName.rawValue: .string(event.context.screen)]
        if case .inList(let list, _) = event.context.placement {
            attributes[Words.Field.listId.rawValue] = .string(list.id)
        }
        for (key, value) in event.properties where words.place(of: key) == .customAttribute {
            attributes[key.rawValue] = .string(value)
        }
        return attributes
    }
}
