import Combine

public struct DefaultObserveSettingUseCase: ObserveSettingUseCase {
    private let repository: SettingsRepository

    public init(repository: SettingsRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(_ key: SettingKey) -> AnyPublisher<Bool, Never> {
        repository.settingsPublisher
            .map { $0.value(for: key) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
