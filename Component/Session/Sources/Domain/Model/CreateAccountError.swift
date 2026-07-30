public enum CreateAccountError: Error, Equatable, Sendable {
    case nameIsMissing
    case invalidEmail
    case invalidPassword
    case emailAlreadyInUse

    /// The shop could not be asked, so whether the account could have been created is
    /// unknown.
    case unavailable
}
