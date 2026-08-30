// Stand-ins for the protocols this package declares, so that every suite
// needing one shares a single definition rather than writing its own.

import Combine
import Settings

@MainActor
public final class StubObserveOfferedSettings: ObserveOfferedSettingsUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<[Setting], Never>
    public private(set) var callCount = 0

    public init(_ settings: [Setting] = []) {
        subject = CurrentValueSubject(settings)
    }

    public func callAsFunction() -> AnyPublisher<[Setting], Never> {
        callCount += 1
        return subject.eraseToAnyPublisher()
    }

    public func send(_ settings: [Setting]) { subject.send(settings) }
}

@MainActor
public final class SpySetSetting: SetSettingUseCase, @unchecked Sendable {
    public init() {}

    public private(set) var calls: [(key: SettingKey, isOn: Bool)] = []

    public func callAsFunction(_ key: SettingKey, isOn: Bool) async -> Result<Void, SettingsError> {
        calls.append((key, isOn))
        return .success(())
    }
}

/// A working double, not a store of canned answers: a successful write updates the same settings
/// stream the screen observes, exactly as the real repository publishes after it keeps a change.
private final class StubSetSetting: SetSettingUseCase, @unchecked Sendable {
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

// MARK: - A working shop, for a journey rather than a single answer

/// Derives what is on offer the way the app does, from a shopper's settings and
/// whether they are signed in, rather than being handed a list.
///
/// Kept apart from `StubObserveOfferedSettings` rather than merged with it. The
/// two answer the same protocol and are not the same double: one is told what
/// to say, this one works it out, and an acceptance test wants the second while
/// a unit test wants the first. Taking the longer of the two — which is what a
/// tool comparing them by size will do — silently swaps one for the other.
public struct StubOfferedSettingsForShopper: ObserveOfferedSettingsUseCase, @unchecked Sendable {
    public let settings: CurrentValueSubject<Settings, Never>
    public let signedIn: CurrentValueSubject<Bool, Never>

    public init(settings: CurrentValueSubject<Settings, Never>, signedIn: CurrentValueSubject<Bool, Never>) {
        self.settings = settings
        self.signedIn = signedIn
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<[Setting], Never> {
        settings
            .combineLatest(signedIn) { Setting.offered(from: $0, signedIn: $1) }
            .eraseToAnyPublisher()
    }
}

/// A working double, not a store of canned answers: a successful write updates
/// the same settings stream the screen observes, exactly as the real repository
/// publishes after it keeps a change.
public final class StubSetSettingThatKeeps: SetSettingUseCase, @unchecked Sendable {
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
