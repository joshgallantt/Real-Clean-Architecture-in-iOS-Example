import Combine
import Session

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: which settings a shopper is offered
/// needs the session, so it is not something `Settings` can answer for itself.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Aggregates: a rule spanning two aggregates belongs
/// outside both. The session arrives as a use case because it belongs to another component and this
/// must not reach past what `Session` publishes; the record arrives as the repository because it is
/// this component's own, which is how every other use case here reads what it needs.
public struct DefaultObserveOfferedSettingsUseCase: ObserveOfferedSettingsUseCase {
    private let repository: SettingsRepository
    private let observeSession: ObserveSessionUseCase

    public init(repository: SettingsRepository, observeSession: ObserveSessionUseCase) {
        self.repository = repository
        self.observeSession = observeSession
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<[Setting], Never> {
        repository.settingsPublisher
            .combineLatest(observeSession()) { Setting.offered(from: $0, signedIn: $1.isLoggedIn) }
            .eraseToAnyPublisher()
    }
}
