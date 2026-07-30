/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the domain's vocabulary
/// for the one thing that can stop a shopper changing their wishlist — it is theirs, so there has
/// to be a them.
public enum WishlistError: Error, Equatable, Sendable {
    case unauthenticated
}
