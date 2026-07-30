/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: stated in the domain's
/// vocabulary, not the auth system's. `.unavailable` is the shop not answering, which is not the
/// same as knowing the answer was no.
public enum LoginError: Error, Equatable, Sendable {
    case invalidEmail
    case invalidPassword
    case invalidCredentials

    case unavailable
}
