import AuthUI
@testable import AuthUIDI

@MainActor
/// Answers the prompt the way the shopper would. `signsIn` is what they do when asked.
public final class StubAuthPresenter: AuthPresenting {
    public var signsIn = false
    public private(set) var timesAsked = 0
    private let onSignIn: () -> Void

    public init(onSignIn: @escaping () -> Void = {}) {
        self.onSignIn = onSignIn
    }

    public func show(_ prompt: AuthenticationPrompt) async -> Bool {
        timesAsked += 1
        if signsIn { onSignIn() }
        return signsIn
    }
}
