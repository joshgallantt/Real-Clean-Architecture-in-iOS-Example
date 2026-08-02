import Combine
import Foundation
import Session
import Settings

@MainActor
/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Repositories. Fowler, *PoEAA* (2002), Ch. 13 —
/// Repository: it keeps and hands back the aggregate and decides nothing about what it means.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: takes an owner and a
/// stream of owners, never a `Session`. It needs to know whose settings are live, not to understand
/// identity.
public final class DefaultSettingsRepository: SettingsRepository {
    private let store: SettingsStore
    private let subject: CurrentValueSubject<Settings, Never>
    private var owner: Owner
    private var cancellables = Set<AnyCancellable>()

    public init(
        store: SettingsStore,
        owner: Owner,
        ownerPublisher: AnyPublisher<Owner, Never>
    ) {
        self.store = store
        self.owner = owner
        self.subject = CurrentValueSubject(store.getSettings(for: owner))

        ownerPublisher
            .sink { [weak self] owner in
                self?.switchOwner(to: owner)
            }
            .store(in: &cancellables)
    }

    public var settings: Settings { subject.value }

    public var settingsPublisher: AnyPublisher<Settings, Never> { subject.eraseToAnyPublisher() }

    /// Fowler, *PoEAA* (2002) — Repository: kept first, published second. Publishing optimistically
    /// and writing behind it would show the shopper a setting that does not exist anywhere, with no
    /// honest moment to take it back.
    public func save(_ settings: Settings) async throws {
        try await store.setSettings(settings, for: owner)
        subject.value = settings
    }

    private func switchOwner(to owner: Owner) {
        guard owner != self.owner else { return }
        self.owner = owner
        subject.value = store.getSettings(for: owner)
    }
}
