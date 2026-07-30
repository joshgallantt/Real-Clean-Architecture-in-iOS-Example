/// Evans, *Domain-Driven Design* (2003) — Making Implicit Concepts Explicit: whose data this is, as
/// distinct from whether anyone is authenticated. The two come apart, because a guest owns a real
/// bag and a real search history. `Session` answers the second question; this answers the first.
///
/// Evans — Shared Kernel: one definition, shared by every context that keeps something per shopper.
/// A second definition would be a second answer, and nothing would keep the two honest.
public enum Owner: Equatable, Hashable, Sendable {
    case guest
    case signedIn(UserID)

    /// Evans, *Domain-Driven Design* (2003) — Assertions: exhaustive over `Session` rather than
    /// reading a derived property, so a new kind of session cannot silently become a guest and swap
    /// someone's bag out from under them. Adding a case stops the build here, where the decision
    /// belongs.
    public init(_ session: Session) {
        switch session {
        case .guest:
            self = .guest
        case .authenticated(let user):
            self = .signedIn(user.id)
        }
    }
}
