import Session

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: turning a domain
/// failure into something worth reading is a presentation decision, so the wording lives here
/// rather than in `Session`.
///
/// A type of its own rather than an extension on the errors: they are declared in another module,
/// and behaviour bolted onto them from here would not be visible to anyone reading them. What
/// belongs to presentation is named as presentation's.
enum AuthenticationErrorMessages {
    static func message(for error: LoginError) -> String {
        switch error {
        case .invalidEmail: "Enter a valid email address."
        case .invalidPassword: "Passwords are at least \(Password.minimumLength) characters."
        case .invalidCredentials: "Invalid email or password."
        case .unavailable: "We couldn't reach the shop. Please try again."
        }
    }

    static func message(for error: CreateAccountError) -> String {
        switch error {
        case .nameIsMissing: "First name is required."
        case .invalidEmail: "Enter a valid email address."
        case .invalidPassword: "Passwords are at least \(Password.minimumLength) characters."
        case .emailAlreadyInUse: "An account with this email already exists."
        case .unavailable: "We couldn't reach the shop. Please try again."
        }
    }
}
