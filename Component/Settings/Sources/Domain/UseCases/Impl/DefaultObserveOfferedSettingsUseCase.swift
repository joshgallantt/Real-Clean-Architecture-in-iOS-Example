import Combine
import Session

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
/// Service Layer.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
public protocol ObserveOfferedSettingsUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<[Setting], Never>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: which settings a shopper is offered
/// needs the session, so it is not something `Settings` can answer for itself.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Aggregates: a rule spanning two aggregates belongs
/// outside both, which is why this composes the two use cases that publish them rather than reaching
/// into either.
public struct DefaultObserveOfferedSettingsUseCase: ObserveOfferedSettingsUseCase {
    private let observeSettings: ObserveSettingsUseCase
    private let observeSession: ObserveSessionUseCase

    public init(observeSettings: ObserveSettingsUseCase, observeSession: ObserveSessionUseCase) {
        self.observeSettings = observeSettings
        self.observeSession = observeSession
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<[Setting], Never> {
        observeSettings()
            .combineLatest(observeSession()) { Setting.offered(from: $0, signedIn: $1.isLoggedIn) }
            .eraseToAnyPublisher()
    }
}
