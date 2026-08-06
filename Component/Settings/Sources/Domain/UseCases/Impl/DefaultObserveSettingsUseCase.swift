import Combine

public struct DefaultObserveSettingsUseCase: ObserveSettingsUseCase {
    private let repository: SettingsRepository

    public init(repository: SettingsRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<Settings, Never> {
        repository.settingsPublisher
    }
}
