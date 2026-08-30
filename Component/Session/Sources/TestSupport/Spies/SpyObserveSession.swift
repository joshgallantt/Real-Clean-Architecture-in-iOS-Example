import Combine
import Session

/// A spy rather than a stub: it answers *and* records that it was asked.
///
/// The kind is in the name because the kind is what the test using it verifies.
/// One copy of this had been called `StubObserveSession` while counting its
/// calls, which reads in review as a type that does not do the thing the test
/// then asserts about.
@MainActor
public final class SpyObserveSession: ObserveSessionUseCase {
    private let subject: CurrentValueSubject<Session, Never>
    public private(set) var callCount = 0

    public init(initial: Session = .guest) {
        subject = CurrentValueSubject(initial)
    }

    public func callAsFunction() -> AnyPublisher<Session, Never> {
        callCount += 1
        return subject.eraseToAnyPublisher()
    }

    public func send(_ session: Session) {
        subject.send(session)
    }
}
