import Combine
import Waitlist

/// A fake in Meszaros' sense: a working implementation, unfit for production. It keeps the waitlist
/// in memory, so the real use cases genuinely read, apply and save. `whenItCannotKeep` is the one
/// thing a disk does that memory does not.
@MainActor
public final class FakeWaitlistRepository: WaitlistRepository {
    private let subject: CurrentValueSubject<Waitlist, Never>

    public var whenItCannotKeep = false

    public init(waitlist: Waitlist = Waitlist()) {
        subject = CurrentValueSubject(waitlist)
    }

    public var waitlist: Waitlist { subject.value }
    public var waitlistPublisher: AnyPublisher<Waitlist, Never> { subject.eraseToAnyPublisher() }

    /// The yield is the round trip. A store that keeps something suspends before it has kept it,
    /// and a shopper can tap again inside that gap — which is only true of this stand-in if it
    /// suspends too.
    public func save(_ waitlist: Waitlist) async throws {
        await Task.yield()
        if whenItCannotKeep { throw CouldNotKeep() }
        subject.value = waitlist
    }

    public struct CouldNotKeep: Error {}
}
