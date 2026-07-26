/// A step of the flow, and so also where the presenter can start it.
///
/// Two forms, not a hierarchy: logging in and creating an account are the same question
/// answered differently. The flow used to ask which one first; it doesn't any more, because
/// that is a question the user often can't answer and the backend always can.
enum AuthenticationStep: Hashable {
    case logIn
    case createAccount

    /// The other way in, reachable from either side.
    var peer: AuthenticationStep {
        switch self {
        case .logIn: .createAccount
        case .createAccount: .logIn
        }
    }

    /// What the step says for itself, when no feature has supplied a reason of its own.
    var header: AuthHeader {
        switch self {
        case .logIn:
            AuthHeader(
                icon: "bag.fill",
                title: "Welcome Back",
                subtitle: "Log in to sync your bag and wishlist."
            )
        case .createAccount:
            AuthHeader(
                icon: "bag.fill",
                title: "Create Account",
                subtitle: "Join to save your bag and wishlist across devices."
            )
        }
    }

    /// How the link to `peer` reads from here. Phrased as the user's situation rather than
    /// as a destination, because that's what they know at this point.
    var peerLinkTitle: String {
        switch self {
        case .logIn: "New here? Create Account"
        case .createAccount: "Already have an account? Log In"
        }
    }
}
