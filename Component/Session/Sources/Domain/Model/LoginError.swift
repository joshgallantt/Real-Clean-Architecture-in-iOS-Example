public enum LoginError: Error, Equatable, Sendable {
    case invalidEmail
    case invalidPassword
    case invalidCredentials

    /// The shop could not be asked. Nothing is known about whether the credentials were
    /// good, which is different from knowing they were bad.
    case unavailable
}
