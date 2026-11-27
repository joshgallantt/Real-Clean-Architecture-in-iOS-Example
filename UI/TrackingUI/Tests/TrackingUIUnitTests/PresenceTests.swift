import Testing
@testable import TrackingUI

@Suite("Telling a shopper arriving from SwiftUI passing through")
struct PresenceTests {
    private let start = ContinuousClock.now

    @Test("Coming into view for the first time is an arrival")
    func firstTime() {
        #expect(Presence().isArrival(at: start))
    }

    @Test("Coming back a moment after leaving is not an arrival: that is a push, part-way through")
    func straightBack() {
        var presence = Presence()
        presence.left(at: start)

        #expect(!presence.isArrival(at: start + .milliseconds(10)))
    }

    @Test("Coming back after any time a person could take is an arrival")
    func comingBack() {
        var presence = Presence()
        presence.left(at: start)

        #expect(presence.isArrival(at: start + .milliseconds(100)))
        #expect(presence.isArrival(at: start + .seconds(3)))
    }
}
