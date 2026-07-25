/// Presents the auth flow when a caller needs an authenticated session. If the user is
/// already authenticated this returns immediately; otherwise it presents login/create
/// account and suspends until the user completes it or dismisses it.
@MainActor
public protocol AuthPresenting: AnyObject {
    /// - Returns: `true` if the user is authenticated (already was, or just completed the
    ///   auth flow), `false` if they dismissed it without authenticating.
    @discardableResult
    func requireAuthentication() async -> Bool
}
