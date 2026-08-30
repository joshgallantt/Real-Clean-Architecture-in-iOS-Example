// Stand-ins for the protocols this package declares, so that every suite
// needing one shares a single definition rather than writing its own.

import Combine
import Product
import Session
import StockAlert

@MainActor
public final class StubObserveWaitlistStatus: ObserveWaitlistStatusUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Bool, Never>

    public init(_ isWaiting: Bool = false) {
        subject = CurrentValueSubject(isWaiting)
    }

    public func send(_ isWaiting: Bool) { subject.value = isWaiting }

    public func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never> { subject.eraseToAnyPublisher() }
}

@MainActor
public final class StubSetStockAlert: SetStockAlertForProductUseCase, @unchecked Sendable {
    public init() {}

    public var result: Result<Void, StockAlertError> = .success(())
    public var onSuccess: (Bool) -> Void = { _ in }
    public private(set) var calls: [(productId: ProductID, isOn: Bool)] = []

    public func callAsFunction(productId: ProductID, isOn: Bool) async -> Result<Void, StockAlertError> {
        calls.append((productId, isOn))
        await Task.yield()
        if case .success = result { onSuccess(isOn) }
        return result
    }
}

@MainActor
/// A working repository rather than a stub with canned answers, so the real use cases genuinely
/// read, apply and save. `whenItCannotKeep` is the one thing a disk does that memory does not.
public final class InMemoryStockAlertRepository: StockAlertRepository {
    public init() {}

    private let subject = CurrentValueSubject<StockAlerts, Never>(StockAlerts())

    public var isSignedIn = true
    public var signsInOnPrompt = false
    public var whenItCannotKeep = false

    public var alerts: StockAlerts { subject.value }
    public var alertsPublisher: AnyPublisher<StockAlerts, Never> { subject.eraseToAnyPublisher() }

    public var session: GetSessionUseCase { Session_(repository: self) }

    /// The yield is the round trip. A store that keeps something suspends before it has kept it,
    /// and a shopper can tap again inside that gap — which is only true of this stand-in if it
    /// suspends too.
    public func save(_ alerts: StockAlerts) async throws {
        await Task.yield()
        if whenItCannotKeep { throw CouldNotKeep() }
        subject.value = alerts
    }

    public struct CouldNotKeep: Error {}

    private struct Session_: GetSessionUseCase, @unchecked Sendable {
        let repository: InMemoryStockAlertRepository

        @MainActor
        func callAsFunction() -> Session {
            guard repository.isSignedIn else { return .guest }
            return .authenticated(
                User(
                    id: UserID(rawValue: 42),
                    email: Email("shopper@example.com"),
                    name: PersonName(first: "Ada", last: nil)
                )
            )
        }
    }
}
