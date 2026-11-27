import Foundation
import Money
import Tracking

/// Fowler, *PoEAA* (2002), Ch. 18 — Mapper: an event, in Google's terms — a name and a flat bag of
/// parameters. GA4 and Firebase are the same analytics product reached two ways, so they share what
/// an event means to Google; each has its own mapper for what it does with that.
///
/// It maps what the event says about itself and asks `GoogleAnalyticsVocabulary` for the words, so
/// an event added to `EventName` tomorrow is a line there and nothing here.
struct GoogleAnalyticsEventMapper {
    private typealias Words = GoogleAnalyticsVocabulary

    private let words = Words()

    /// A tap on an item in a list is the one event Google names by where it happened.
    func name(of event: TrackingEvent) -> String {
        if event.name == .elementSelected, !event.items.isEmpty, case .inList = event.context.placement {
            return Words.ListEvent.selectItem.rawValue
        }
        return words.eventName(for: event.name)
    }

    func parameters(of event: TrackingEvent) -> [String: JSONValue] {
        var params: [String: JSONValue] = [:]
        for (key, value) in event.properties {
            params[words.parameterKey(for: key)] = text(value)
        }

        switch event.context.placement {
        case .onScreen:
            if !event.items.isEmpty {
                params[Words.Parameter.items.rawValue] = .array(event.items.map(item))
            }
        case .inList(let list, let index):
            params[Words.Parameter.itemListId.rawValue] = text(list.id)
            params[Words.Parameter.itemListName.rawValue] = text(list.name)
            if event.items.isEmpty {
                params[Words.Parameter.index.rawValue] = .integer(index)
            } else {
                params[Words.Parameter.items.rawValue] = .array(event.items.map { item($0, at: index, in: list) })
            }
        }

        /// `value` and `currency` together or not at all: Google ignores a value it cannot price.
        if let worth = Worth(of: event.items) {
            params[Words.Parameter.value.rawValue] = .number(worth.amount)
            params[Words.Parameter.currency.rawValue] = text(worth.currency)
        }
        return params
    }

    /// The parameters of a `view_item_list`: items seen in one list, each with its own position.
    func itemListViewed(_ items: [JSONValue], in list: TrackingContext.List) -> [String: JSONValue] {
        [
            Words.Parameter.itemListId.rawValue: text(list.id),
            Words.Parameter.itemListName.rawValue: text(list.name),
            Words.Parameter.items.rawValue: .array(items)
        ]
    }

    func screenName(of event: TrackingEvent) -> JSONValue {
        text(event.context.screen)
    }

    func item(_ item: TrackedItem) -> JSONValue {
        .object(fields(of: item))
    }

    /// The list goes on the item as well as on the event, because Google reads it from the item first.
    func item(_ item: TrackedItem, at index: Int, in list: TrackingContext.List) -> JSONValue {
        var fields = fields(of: item)
        fields[Words.Parameter.index.rawValue] = .integer(index)
        fields[Words.Parameter.itemListId.rawValue] = text(list.id)
        fields[Words.Parameter.itemListName.rawValue] = text(list.name)
        return .object(fields)
    }

    private func fields(of item: TrackedItem) -> [String: JSONValue] {
        var fields: [String: JSONValue] = [Words.Item.id.rawValue: text(item.id), Words.Item.name.rawValue: text(item.name)]
        if case .product(let category, let price, let quantity) = item.details {
            fields[Words.Item.category.rawValue] = text(category)
            fields[Words.Item.price.rawValue] = .number(price.amount)
            fields[Words.Item.quantity.rawValue] = .integer(quantity)
        }
        return fields
    }

    /// Cut to what Google keeps, which is the part a report shows anyway.
    private func text(_ value: String) -> JSONValue {
        .string(String(value.prefix(words.maxTextLength)))
    }
}
