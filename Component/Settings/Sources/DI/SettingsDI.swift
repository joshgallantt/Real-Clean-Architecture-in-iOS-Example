import Combine
import Foundation
import Session
import Settings
import SettingsData

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: wiring, and nothing else. It
/// is the only thing that knows the concrete types, so it is the only thing that has to change when
/// one is swapped. Not unit tested — there is no behaviour here to test.
///
/// Fowler, *Inversion of Control Containers and the Dependency Injection Pattern* (2004) —
/// Dependency Injection.
public struct SettingsDI {
    private let repository: SettingsRepository

    public let observeSettingsUseCase: ObserveSettingsUseCase
    public let observeOfferedSettingsUseCase: ObserveOfferedSettingsUseCase
    public let setSettingUseCase: SetSettingUseCase

    @MainActor
    public init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        store: SettingsStore = FileSettingsStore()
    ) {
        /// Evans, *Domain-Driven Design* (2003) — Bounded Context: turning a session into an owner
        /// happens here, once, at the wiring boundary. What the repository receives is who the
        /// settings belong to.
        let repository = DefaultSettingsRepository(
            store: store,
            owner: Owner(getSession()),
            ownerPublisher: observeSession()
                .map(Owner.init)
                .removeDuplicates()
                .eraseToAnyPublisher()
        )
        self.repository = repository

        self.observeSettingsUseCase = DefaultObserveSettingsUseCase(repository: repository)
        self.observeOfferedSettingsUseCase = DefaultObserveOfferedSettingsUseCase(
            observeSettings: observeSettingsUseCase,
            observeSession: observeSession
        )
        self.setSettingUseCase = DefaultSetSettingUseCase(repository: repository, getSession: getSession)
    }
}
