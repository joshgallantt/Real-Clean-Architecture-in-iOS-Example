import Combine
import Foundation
import Settings
@testable import SettingsUI

@MainActor
final class StubObserveOfferedSettings: ObserveOfferedSettingsUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<[Setting], Never>
    private(set) var callCount = 0

    init(_ settings: [Setting] = []) {
        subject = CurrentValueSubject(settings)
    }

    func callAsFunction() -> AnyPublisher<[Setting], Never> {
        callCount += 1
        return subject.eraseToAnyPublisher()
    }

    func send(_ settings: [Setting]) { subject.send(settings) }
}

@MainActor
final class SpySetSetting: SetSettingUseCase, @unchecked Sendable {
    private(set) var calls: [(key: SettingKey, isOn: Bool)] = []

    func callAsFunction(_ key: SettingKey, isOn: Bool) async -> Result<Void, SettingsError> {
        calls.append((key, isOn))
        return .success(())
    }
}

@MainActor
func settle() async {
    for _ in 0..<200 { await Task.yield() }
}
