import Session

/// Turning a domain failure into something worth reading is a presentation decision, so the
/// wording lives here rather than in `Session`.
extension LoginError {
    var userMessage: String {
        switch self {
        case .emailIsEmpty: "Email is required."
        case .passwordIsEmpty: "Password is required."
        case .invalidCredentials: "Invalid email or password."
        case .unknown: "An unknown error occurred. Please try again later."
        }
    }
}

extension CreateAccountError {
    var userMessage: String {
        switch self {
        case .firstNameIsEmpty: "First name is required."
        case .emailIsEmpty: "Email is required."
        case .passwordIsEmpty: "Password is required."
        case .emailAlreadyInUse: "An account with this email already exists."
        case .unknown: "Something went wrong. Please try again."
        }
    }
}
