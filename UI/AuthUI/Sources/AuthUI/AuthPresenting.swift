/// The port features call to surface the authentication flow. Deliberately one method: a
/// feature says why it needs an account, and has no say in which sheets appear, in what
/// order, or how they are presented.
@MainActor
public protocol AuthPresenting: AnyObject {
    /// Presents `prompt`, unless the user is already authenticated and there is nothing to
    /// ask.
    ///
    /// - Returns: `true` if the user is authenticated — they already were, or they just
    ///   completed the flow. `false` if they dismissed it first.
    @discardableResult
    func show(_ prompt: AuthenticationPrompt) async -> Bool
}
