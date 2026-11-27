import Money
import Tracking

/// Fowler, *PoEAA* (2002), Ch. 18 — Mapper: an event as one line a person can read, in no vendor's
/// words. Keys are sorted, so the same event is the same line every time.
struct LoggerEventMapper {
    func map(_ event: TrackingEvent) -> String {
        var parts = [event.name.rawValue, "screen=\(event.context.screen)"]
        if let position = event.context.listPosition {
            parts.append("list=\(position.list.id)[\(position.index)]")
        }
        parts += event.properties.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }
        if !event.items.isEmpty {
            parts.append("items=" + event.items.map(text).joined(separator: ","))
        }
        return parts.joined(separator: " | ")
    }

    private func text(_ item: TrackedItem) -> String {
        guard case .product(_, let price, let quantity) = item.details else { return item.id }
        return "\(item.id) x\(quantity) @\(price.amount) \(price.currency.code)"
    }
}
