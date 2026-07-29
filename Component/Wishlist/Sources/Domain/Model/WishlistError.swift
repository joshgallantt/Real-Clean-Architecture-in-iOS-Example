/// The only thing that can stop a shopper changing their wishlist: it is theirs, so
/// they have to be signed in for there to be a "theirs" to change.
public enum WishlistError: Error, Equatable, Sendable {
    case unauthenticated
}
