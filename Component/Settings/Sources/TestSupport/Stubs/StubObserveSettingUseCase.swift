import Combine
import Settings

/// Says whether each setting is on, and can be told a shopper has changed one. A setting it has not
/// been told is off is on, which is what every setting that shows a section is worth untouched.
@MainActor
public final class StubObserveSettingUseCase: ObserveSettingUseCase {
    private let turnedOff: CurrentValueSubject<Set<SettingKey>, Never>

    public init(turnedOff: Set<SettingKey>) {
        self.turnedOff = CurrentValueSubject(turnedOff)
    }

    public func callAsFunction(_ key: SettingKey) -> AnyPublisher<Bool, Never> {
        turnedOff
            .map { !$0.contains(key) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public func turn(_ key: SettingKey, on isOn: Bool) {
        turnedOff.value = isOn ? turnedOff.value.subtracting([key]) : turnedOff.value.union([key])
    }
}
