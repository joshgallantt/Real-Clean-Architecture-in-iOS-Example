import Testing
import Tracking
@testable import TrackingUI

@Suite("Where a view is, as each level above it says")
struct TrackingScopeTests {
    private let home = "home"
    private let beauty = TrackingContext.List(id: "beauty", name: "Beauty")

    @Test("A view on a screen reports against the screen")
    func screen() {
        #expect(TrackingScope.screen(home).context == .screen(home))
    }

    @Test("A view in a list but at no position — a heading — reports against the screen")
    func listWithoutPosition() {
        #expect(TrackingScope.screen(home).entering(beauty).context == .screen(home))
    }

    @Test("A view at a position in a list reports that position in that list")
    func position() {
        #expect(TrackingScope.screen(home).entering(beauty).at(3).context == .list(home, beauty, index: 3))
    }

    @Test("A list inside a position starts again at no position")
    func nestedList() {
        let toys = TrackingContext.List(id: "toys", name: "Toys")

        #expect(TrackingScope.screen(home).entering(beauty).at(3).entering(toys).at(1).context == .list(home, toys, index: 1))
    }

    @Test("A position with no list above it is just the screen")
    func positionWithoutList() {
        #expect(TrackingScope.screen(home).at(2).context == .screen(home))
    }

    @Test("A view with no screen above it has no screen name to report, whatever else is set")
    func noScreen() {
        #expect(TrackingScope.noScreen.entering(beauty).at(1).context == .screen(""))
    }
}
