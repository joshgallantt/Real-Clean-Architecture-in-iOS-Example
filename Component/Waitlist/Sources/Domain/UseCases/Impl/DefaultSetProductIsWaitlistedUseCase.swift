import Product
import Session

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: being told when something returns
/// needs somewhere to tell them, which a guest has not given. The waitlist cannot decide that for
/// itself — it needs the session — so the rule lives here rather than on the aggregate.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Aggregates: a rule spanning two aggregates belongs
/// outside both.
public struct DefaultSetProductIsWaitlistedUseCase: SetProductIsWaitlistedUseCase {
    private let repository: WaitlistRepository
    private let getSession: GetSessionUseCase

    public init(repository: WaitlistRepository, getSession: GetSessionUseCase) {
        self.repository = repository
        self.getSession = getSession
    }

    @MainActor
    @discardableResult
    public func callAsFunction(
        productId: ProductID,
        isWaitlisted: Bool
    ) async -> Result<Void, WaitlistError> {
        guard getSession().isLoggedIn else {
            return .failure(.unauthenticated)
        }

        let waitlist = repository.waitlist
        let updated = isWaitlisted
            ? waitlist.adding(WaitlistItem(productId: productId))
            : waitlist.removing(productId: productId)

        /// Nothing to write, nothing that can fail. Tapping a bell that is already on is not an
        /// error and must not be reported as one.
        guard updated != waitlist else { return .success(()) }

        do {
            try await repository.save(updated)
            return .success(())
        } catch {
            return .failure(.unavailable)
        }
    }
}
