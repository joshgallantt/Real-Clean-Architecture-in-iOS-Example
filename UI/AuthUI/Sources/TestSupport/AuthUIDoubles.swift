// Stand-ins for the protocols this package declares, so that every suite
// needing one shares a single definition rather than writing its own.

import AuthUI

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

@MainActor
public final class SpyAuthPresenter: AuthPresenting {
    public init() {}

    public private(set) var wasAsked = false
    public var answer = false
    public var onShown: (() -> Void)?

    public func show(_ prompt: AuthenticationPrompt) async -> Bool {
        wasAsked = true
        onShown?()
        return answer
    }
}
