/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: stated in the domain's
/// vocabulary, not the storage's. A wishlist is a shopper's, so there has to be a them — and
/// whatever keeps it can fail to keep it, which they need telling about either way.
///
/// `.unavailable` is deliberately one case. A disk that would not write, a request that never
/// arrived and a payload that came back unreadable are the same fact to a shopper: their wishlist
/// did not change. Telling them apart here would be the transport's vocabulary leaking inward, and
/// nothing in the domain would do anything different with the distinction.
public enum WishlistError: Error, Equatable, Sendable {
    case unauthenticated
    case unavailable
}
