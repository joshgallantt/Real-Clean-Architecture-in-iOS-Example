import Combine
import Foundation
import Session
import Settings

@MainActor
/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Repositories. Fowler, *PoEAA* (2002), Ch. 13 —
/// Repository: it keeps and hands back the aggregate and decides nothing about what it means.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: takes a session and a
/// stream of sessions, and reads only who is signed in. It needs to know whose settings are live,
/// not to understand identity, so it compares ids — a changed profile is not a changed owner.
public final class DefaultSettingsRepository: SettingsRepository {
    private let store: SettingsStore
    private let subject: CurrentValueSubject<Settings, Never>
    private var session: Session
    private var cancellables = Set<AnyCancellable>()

    public init(
        store: SettingsStore,
        session: Session,
        sessionPublisher: AnyPublisher<Session, Never>
    ) {
        self.store = store
        self.session = session
        self.subject = CurrentValueSubject(store.getSettings(for: session))

        sessionPublisher
            .sink { [weak self] session in
                self?.switchSession(to: session)
            }
            .store(in: &cancellables)
    }

    public var settings: Settings { subject.value }

    public var settingsPublisher: AnyPublisher<Settings, Never> { subject.eraseToAnyPublisher() }

    /// Fowler, *PoEAA* (2002) — Repository: kept first, published second. Publishing optimistically
    /// and writing behind it would show the shopper a setting that does not exist anywhere, with no
    /// honest moment to take it back.
    public func save(_ settings: Settings) async throws {
        try await store.setSettings(settings, for: session)
        subject.value = settings
    }

    private func switchSession(to session: Session) {
        guard session.user?.id != self.session.user?.id else { return }
        self.session = session
        subject.value = store.getSettings(for: session)
    }
}
