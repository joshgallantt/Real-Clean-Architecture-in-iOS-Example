import AccountUI

/// Records where the account screen asked to go.
///
/// This could not be written while the rows arrived as opaque `AnyView`s from
/// the composition root: there was nothing to stand in for, and no test could
/// say that tapping "Your Orders" went anywhere. A navigation protocol is what
/// makes the question askable.
@MainActor
public final class SpyAccountNavigation: AccountNavigation {
    public private(set) var openedOrderHistory = 0
    public private(set) var openedSettings = 0

    public init() {}

    /// `nonisolated` with `assumeIsolated`, matching the other navigation
    /// doubles: the protocol is not isolated, but everything that calls it is
    /// on the main actor and the counters are only ever read from a test there.
    public nonisolated func openOrderHistory() {
        MainActor.assumeIsolated { openedOrderHistory += 1 }
    }

    public nonisolated func openSettings() {
        MainActor.assumeIsolated { openedSettings += 1 }
    }
}
