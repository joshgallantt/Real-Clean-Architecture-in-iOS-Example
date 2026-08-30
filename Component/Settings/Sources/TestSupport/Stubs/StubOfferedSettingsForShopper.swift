import Combine
import Settings

/// Derives what is on offer the way the app does, from a shopper's settings and
/// whether they are signed in, rather than being handed a list.
///
/// Kept apart from `StubObserveOfferedSettings` rather than merged with it. The
/// two answer the same protocol and are not the same double: one is told what
/// to say, this one works it out, and an acceptance test wants the second while
/// a unit test wants the first. Taking the longer of the two — which is what a
/// tool comparing them by size will do — silently swaps one for the other.
@MainActor
public struct StubOfferedSettingsForShopper: ObserveOfferedSettingsUseCase {
    public let settings: CurrentValueSubject<Settings, Never>
    public let signedIn: CurrentValueSubject<Bool, Never>

    public init(settings: CurrentValueSubject<Settings, Never>, signedIn: CurrentValueSubject<Bool, Never>) {
        self.settings = settings
        self.signedIn = signedIn
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<[Setting], Never> {
        settings
            .combineLatest(signedIn) { Setting.offered(from: $0, signedIn: $1) }
            .eraseToAnyPublisher()
    }
}
