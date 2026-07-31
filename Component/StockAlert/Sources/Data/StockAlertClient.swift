import Foundation
import Product
import Session
import StockAlert

/// Fowler, *PoEAA* (2002), Ch. 18 — Gateway: wraps one external system behind a domain-shaped call.
/// The shop is told who is waiting on what, and answers which of those are back on the shelf.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: whether something is back
/// is a fact the shop owns, not one the app derives. Reading it out of a product's stock count
/// would make the catalog answerable for a promise the alert service made — and would only ever be
/// as fresh as the last time a screen happened to look.
public protocol StockAlertClient: Sendable {
    /// The whole set, the way the store takes it. The shop is told what this shopper is waiting on
    /// rather than what changed, so there is no sequence of edits to arrive out of order.
    func setAlerts(_ productIds: [ProductID], for owner: UserID) async throws

    /// Which of them the shop has put back on the shelf.
    func backInStock(for owner: UserID) async throws -> [ProductID]
}

/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the adapter behind the
/// port, and the only thing that would change the day there is a real service to call. It ships
/// rather than hiding in a test target, for the same reason `FakeAuthClient` and
/// `FakePaymentClient` do — there is nothing real to talk to, and a seam nothing compiles against
/// rots.
///
/// It restocks per registration rather than on a shop-wide clock: something is back once
/// `restockAfter` has passed since *this shopper* asked about it. That is both what a real service
/// looks like from outside and what makes the promise demonstrable — tap the bell, and that item
/// is the one that comes back.
public actor FakeStockAlertClient: StockAlertClient {
    private let restockAfter: TimeInterval
    private let now: @Sendable () -> Date
    private var askedAt: [UserID: [ProductID: Date]] = [:]

    public init(restockAfter: TimeInterval, now: @escaping @Sendable () -> Date = Date.init) {
        self.restockAfter = restockAfter
        self.now = now
    }

    public func setAlerts(_ productIds: [ProductID], for owner: UserID) async throws {
        var registrations = askedAt[owner] ?? [:]

        /// Kept from the previous registration where there was one. A shopper who asks about a
        /// second thing has not restarted the wait on the first, and re-sending the set is how this
        /// endpoint is told anything at all.
        let asked = now()
        var updated: [ProductID: Date] = [:]
        for id in productIds {
            updated[id] = registrations[id] ?? asked
        }

        registrations = updated
        askedAt[owner] = registrations
    }

    public func backInStock(for owner: UserID) async throws -> [ProductID] {
        let due = now().addingTimeInterval(-restockAfter)
        return (askedAt[owner] ?? [:])
            .filter { $0.value <= due }
            .map(\.key)
    }
}
