import Foundation
import Money
import Order

/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the adapter behind
/// `PaymentClient`, and the only thing in the app that would change on the day there is a real
/// processor to call. It ships rather than hiding in a test target, for the same reason
/// `FakeAuthClient` does — there is no real one to talk to, and a seam nothing compiles against
/// rots.
///
/// `outcome` is how a shop with no processor can still be made to decline. It is a constructor
/// argument rather than a flag read from anywhere, so nothing but the composition root can reach it.
public struct FakePaymentClient: PaymentClient {
    public enum Outcome: Sendable {
        case succeeds
        case declines
        case unavailable
    }

    private let outcome: Outcome

    public init(_ outcome: Outcome = .succeeds) {
        self.outcome = outcome
    }

    public func pay(_ amount: Money) async -> Result<PaymentReference, PaymentFailure> {
        switch outcome {
        case .succeeds: .success(PaymentReference(rawValue: UUID().uuidString))
        case .declines: .failure(.declined)
        case .unavailable: .failure(.unavailable)
        }
    }
}
