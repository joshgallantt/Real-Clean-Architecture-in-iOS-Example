import Session

/// Evans, *Domain-Driven Design* (2003) — Making Implicit Concepts Explicit: not a restatement of
/// `Session`, though the shape is close. `Session` answers whether anyone is authenticated; this
/// answers whose bag is live — and they come apart, because a guest owns a real bag. Wishlist
/// answers the same question with `UserID?`, where `nil` means no list exists at all.
///
/// Evans — Value Objects. `UserID` is imported, not copied.
public enum BagOwner: Equatable, Hashable, Sendable {
    case guest
    case shopper(UserID)

    /// Evans, *Domain-Driven Design* (2003) — Assertions: exhaustive over `Session` rather than
    /// reading a derived property, so a new kind of session cannot silently become a guest and swap
    /// a shopper's bag out from under them. Adding a case stops the build here, where the decision
    /// belongs.
    public init(_ session: Session) {
        switch session {
        case .guest:
            self = .guest
        case .authenticated(let user):
            self = .shopper(user.id)
        }
    }
}
