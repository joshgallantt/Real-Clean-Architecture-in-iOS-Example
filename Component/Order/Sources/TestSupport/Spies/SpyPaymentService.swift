import Money
import Order
import Product
import Synchronization

/// Whoever takes the money, standing still: it answers however it was told to
/// and remembers every amount it was asked for.
///
/// State lives in a `Mutex`, so the compiler can see this is safe to share
/// rather than being asked to take it on trust.
public final class SpyPaymentService: PaymentService {
    private struct State {
        var outcome: Result<PaymentReference, PaymentFailure> = .success(PaymentReference(rawValue: "ref"))
        var amountsAskedFor: [Money] = []
    }

    private let state = Mutex(State())

    public init() {}

    public var outcome: Result<PaymentReference, PaymentFailure> {
        get { state.withLock { $0.outcome } }
        set { state.withLock { $0.outcome = newValue } }
    }

    public var amountsAskedFor: [Money] { state.withLock { $0.amountsAskedFor } }

    public var timesAsked: Int { amountsAskedFor.count }

    public func pay(_ amount: Money) async -> Result<PaymentReference, PaymentFailure> {
        state.withLock { state in
            state.amountsAskedFor.append(amount)
            return state.outcome
        }
    }
}
