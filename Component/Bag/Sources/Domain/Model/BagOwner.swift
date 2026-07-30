import Session

/// Whose bag it is.
///
/// Not a restatement of `Session`, though it is nearly the same shape. `Session` answers
/// whether anyone is authenticated; this answers whose bag is the live one — and the two come
/// apart, because a guest has a real bag. That is the whole point of letting someone shop
/// before they sign in, so being nobody in particular is one of the cases rather than the
/// absence of one.
///
/// The features that keep something per shopper each answer that differently, which is why
/// this is the bag's own type and not one shared concept: a bag belonging to nobody is a real
/// bag with real contents, while a wishlist belonging to nobody does not exist at all, so
/// `WishlistRepository` takes a `UserID?` where `nil` means *there is no list*. Collapsing
/// both to `UserID?` would make "a full bag" and "no list" look like the same state.
///
/// `UserID` is imported rather than copied: identity means the same thing here as it does in
/// `Session`, and inventing a second way to say it would be inventing a second answer.
///
/// What a bag is filed under is the storage layer's business. This says who it belongs to.
public enum BagOwner: Equatable, Hashable, Sendable {
    case guest
    case shopper(UserID)

    /// The one place a session becomes an owner.
    ///
    /// Exhaustive over `Session` deliberately, rather than reading `session.user` and treating
    /// the absence of one as a guest. A new kind of session — expired, locked, whatever it
    /// turns out to be — is a question about whose bag is live, and the answer is not
    /// obviously "the guest's": guessing wrong swaps a shopper's bag out from under them.
    /// Written this way, adding a case stops the build here, where the decision belongs.
    public init(_ session: Session) {
        switch session {
        case .guest:
            self = .guest
        case .authenticated(let user):
            self = .shopper(user.id)
        }
    }
}
