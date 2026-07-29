public enum LoginError: Error, Equatable, Sendable {
    case invalidEmail
    case invalidPassword
    case invalidCredentials
    case unknown
}
