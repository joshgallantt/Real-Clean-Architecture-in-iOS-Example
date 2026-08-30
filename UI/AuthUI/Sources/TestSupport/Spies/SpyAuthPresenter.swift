import AuthUI
@testable import AuthUIDI

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
