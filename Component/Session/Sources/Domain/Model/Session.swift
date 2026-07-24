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
