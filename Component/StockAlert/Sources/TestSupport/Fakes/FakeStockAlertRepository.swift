import Combine
import Product
import Session
import StockAlert

@MainActor
/// A working repository rather than a stub with canned answers, so the real use cases genuinely
/// read, apply and save. `whenItCannotKeep` is the one thing a disk does that memory does not.
public final class FakeStockAlertRepository: StockAlertRepository {
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

    @MainActor
    private struct Session_: GetSessionUseCase {
        let repository: FakeStockAlertRepository

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
