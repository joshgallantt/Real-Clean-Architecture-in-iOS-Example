/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: errors crossing inward are
/// stated in the domain's vocabulary, never the transport's. A timeout, a 500 and an unreadable
/// payload are one thing to a shopper.
///
/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language.
public enum ProductError: Error, Equatable, Sendable {
    case unavailable
    case notFound
}
