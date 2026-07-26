enum AuthMode: Hashable {
    case logIn
    case createAccount

    var peer: AuthMode {
        switch self {
        case .logIn: .createAccount
        case .createAccount: .logIn
        }
    }

    var icon: String { "bag.fill" }

    var title: String {
        switch self {
        case .logIn: "Welcome Back"
        case .createAccount: "Create Account"
        }
    }

    var subtitle: String {
        switch self {
        case .logIn: "Log in to sync your bag and wishlist."
        case .createAccount: "Join to save your bag and wishlist across devices."
        }
    }

    var submitTitle: String {
        switch self {
        case .logIn: "Log In"
        case .createAccount: "Create Account"
        }
    }

    var peerLinkTitle: String {
        switch self {
        case .logIn: "New here? Create Account"
        case .createAccount: "Already have an account? Log In"
        }
    }

    var confirmationTitle: String {
        switch self {
        case .logIn: "Login Successful"
        case .createAccount: "Account Created"
        }
    }
}
