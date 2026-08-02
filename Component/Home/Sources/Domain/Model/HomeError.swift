/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: errors crossing inward are
/// stated in the domain's vocabulary, never the transport's. Home has exactly one way to fail — the
/// shop had nothing worth drawing — so it takes one case, not `ProductError`'s two.
public enum HomeError: Error, Equatable, Sendable {
    case unavailable
}
