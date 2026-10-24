public enum AuthClientError: Error, Equatable {
    case invalidCredentials
    case emailAlreadyInUse
    case networkFailure
    case unknown
}
