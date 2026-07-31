import Foundation
import Order

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: what an order looks
/// like in words. It lives here rather than on the aggregate because a headless order has no use
/// for it, and because how a date or a reference is worded is a screen's decision to change.
extension Order {
    /// A raw UUID is not something a shopper can read out over the phone. The first block is short
    /// enough to quote and long enough to pick one order out of a shopper's own.
    var reference: String {
        "#" + id.rawValue.prefix(8).uppercased()
    }

    var itemCountSummary: String {
        itemCount == 1 ? "1 item" : "\(itemCount) items"
    }

    var placedOnLabel: String {
        placedAt.formatted(date: .abbreviated, time: .omitted)
    }
}
