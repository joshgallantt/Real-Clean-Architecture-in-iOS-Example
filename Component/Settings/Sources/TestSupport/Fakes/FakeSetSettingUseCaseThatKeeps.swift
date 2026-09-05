import Combine
import Settings

/// A working double, not a store of canned answers: a successful write updates
/// the same settings stream the screen observes, exactly as the real repository
/// publishes after it keeps a change.
@MainActor
public final class FakeSetSettingUseCaseThatKeeps: SetSettingUseCase {
    public let settings: CurrentValueSubject<Settings, Never>

    public init(settings: CurrentValueSubject<Settings, Never>) {
        self.settings = settings
    }

    @MainActor
    public func callAsFunction(_ key: SettingKey, isOn: Bool) async -> Result<Void, SettingsError> {
        settings.send(settings.value.setting(key, to: isOn))
        return .success(())
    }
}
