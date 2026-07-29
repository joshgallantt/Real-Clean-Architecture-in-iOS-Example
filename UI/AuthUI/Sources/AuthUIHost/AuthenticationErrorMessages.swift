import Session

/// Turning a domain failure into something worth reading is a presentation decision, so the
/// wording lives here rather than in `Session`.
extension LoginError {
    var userMessage: String {
        switch self {
        case .invalidEmail: "Enter a valid email address."
        case .invalidPassword: "Passwords are at least \(Password.minimumLength) characters."
        case .invalidCredentials: "Invalid email or password."
        case .unknown: "An unknown error occurred. Please try again later."
        }
    }
}

extension CreateAccountError {
    var userMessage: String {
        switch self {
        case .nameIsMissing: "First name is required."
        case .invalidEmail: "Enter a valid email address."
        case .invalidPassword: "Passwords are at least \(Password.minimumLength) characters."
        case .emailAlreadyInUse: "An account with this email already exists."
        case .unknown: "Something went wrong. Please try again."
        }
    }
}
