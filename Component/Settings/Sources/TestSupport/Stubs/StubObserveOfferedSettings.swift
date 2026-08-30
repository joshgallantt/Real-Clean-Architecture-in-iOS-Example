import Combine
import Settings

@MainActor
public final class StubObserveOfferedSettings: ObserveOfferedSettingsUseCase {
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
