public enum CreateAccountError: Error, Equatable, Sendable {
    case nameIsMissing
    case invalidEmail
    case invalidPassword
    case emailAlreadyInUse
    case unknown
}
