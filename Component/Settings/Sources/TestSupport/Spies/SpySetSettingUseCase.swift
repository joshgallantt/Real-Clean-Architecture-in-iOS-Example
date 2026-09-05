import Settings

@MainActor
public final class SpySetSettingUseCase: SetSettingUseCase {
    public init() {}

    public private(set) var calls: [(key: SettingKey, isOn: Bool)] = []

    public func callAsFunction(_ key: SettingKey, isOn: Bool) async -> Result<Void, SettingsError> {
        calls.append((key, isOn))
        return .success(())
    }
}
