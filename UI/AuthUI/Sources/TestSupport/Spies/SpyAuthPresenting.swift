import AuthUI
@testable import AuthUIDI

@MainActor
/// Answers the prompt the way the shopper would, and records having been asked.
/// `signsIn` is what they do when the prompt appears.
///
/// A spy rather than a stub, because being asked is the thing the tests using it
/// assert about. There were two of these — a `SpyAuthPresenting` and a
/// `SpyAuthPresenting` — and both recorded, both answered from a flag, and only
/// one of them said so in its name.
public final class SpyAuthPresenting: AuthPresenting {
    /// What the shopper does when asked.
    public var signsIn = false
    public private(set) var timesAsked = 0

    /// Runs whenever the prompt is shown, signed in or not.
    public var onShown: (() -> Void)?

    /// Runs only when they sign in — for the caller that has to make the thing
    /// they were blocked on start succeeding.
    private let onSignIn: () -> Void

    public var wasAsked: Bool { timesAsked > 0 }

    public init(onSignIn: @escaping () -> Void = {}) {
        self.onSignIn = onSignIn
    }

    public func show(_ prompt: AuthenticationPrompt) async -> Bool {
        timesAsked += 1
        onShown?()
        if signsIn { onSignIn() }
        return signsIn
    }
}
