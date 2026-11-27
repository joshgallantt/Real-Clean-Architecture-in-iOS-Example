/// What a property of an event is called. A closed list for the same reason `EventName` is: the
/// screen that sets a property and the destination that reads it name the same case, and no
/// destination's vocabulary can overlook one.
///
/// The raw value is the key in plain snake_case — what a destination with no key of its own for
/// the property sends. Each is spelled out, so renaming a case cannot rename what a report reads.
public enum PropertyKey: String, CaseIterable, Sendable {
    case element = "element"
    case orderId = "order_id"
    case query = "query"
    case method = "method"
}
