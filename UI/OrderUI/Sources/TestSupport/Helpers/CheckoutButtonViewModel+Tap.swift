import Tracking
@testable import OrderUI

@MainActor
extension CheckoutButtonViewModel {
    /// Where the button is drawn in the app. A test about what a tap does, not where it was, has no
    /// reason to say.
    static let whereItSits = TrackingContext.screen("bag")

    func tapAndSettle() async {
        didTap(in: Self.whereItSits)
        await settle()
    }

    /// Waits for the work the tap started, and nothing else. Watching `isPlacing`
    /// go true and then false again yielded until the flag happened to agree,
    /// which is a guess about how busy the machine is rather than a wait.
    func settle() async {
        await inFlight?.value
    }
}
