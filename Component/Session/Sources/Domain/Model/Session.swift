/// Evans, *Domain-Driven Design* (2003) — Making Implicit Concepts Explicit: a sum type, not an
/// optional user beside a boolean. The two-field version admits a state that cannot exist — logged
/// in, no user.
public enum Session: Equatable, Sendable {
    case guest
    case authenticated(User)

    public var user: User? {
        if case .authenticated(let user) = self { return user }
        return nil
    }

    public var isLoggedIn: Bool {
        if case .authenticated = self { return true }
        return false
    }
}
