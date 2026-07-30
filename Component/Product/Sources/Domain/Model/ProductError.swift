/// What can go wrong asking the shop about its catalog, in the shopper's terms rather than
/// the transport's. A timeout, a 500 and an unreadable payload are one thing to a shopper:
/// the shop did not answer.
public enum ProductError: Error, Equatable, Sendable {
    case unavailable
    case notFound
}
