import Foundation
import Testing
import SearchHistory

@MainActor
@Suite("Coming back to a search")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: a whole feature wired as the
/// composition root wires it, driven only through the use cases the UI is given.
///
/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language: the tests are named in the shopper's
/// words, so a failure reads as a broken journey rather than a broken method.
struct SearchingAgainTests {
    @Test("A shopper who has searched for nothing yet is offered nothing")
    func nothingSearchedYet() {
        #expect(Searcher().recentSearches.isEmpty)
    }

    @Test("A shopper's recent searches are waiting for them, most recent first")
    func recentSearchesAreRemembered() {
        let shopper = Searcher()

        shopper.search(for: "mascara")
        shopper.search(for: "red dress")

        #expect(shopper.recentSearches == ["red dress", "mascara"])
    }

    @Test("Running the same search again moves it back to the top rather than repeating it")
    func repeatedSearch() {
        let shopper = Searcher()

        shopper.search(for: "mascara")
        shopper.search(for: "sofa")
        shopper.search(for: "MASCARA")

        #expect(shopper.recentSearches == ["MASCARA", "sofa"])
    }

    @Test("Spaces either side of what they typed do not make it a different search")
    func surroundingSpaceIsNotASearch() {
        let shopper = Searcher()

        shopper.search(for: "sofa")
        shopper.search(for: "  sofa  ")

        #expect(shopper.recentSearches == ["sofa"])
    }

    @Test("Words that only differ inside are different searches")
    func differentWordsAreDifferentSearches() {
        let shopper = Searcher()

        shopper.search(for: "sofa")
        shopper.search(for: "sofas")

        #expect(shopper.recentSearches == ["sofas", "sofa"])
    }

    @Test("Tapping search with nothing typed leaves the list alone")
    func blankSearch() {
        let shopper = Searcher()
        shopper.search(for: "mascara")

        shopper.search(for: "  ")
        shopper.search(for: "")

        #expect(shopper.recentSearches == ["mascara"])
    }

    @Test("Only the last ten are kept, however many a shopper runs")
    func onlyTheLastTen() {
        let shopper = Searcher()

        for i in 1...15 {
            shopper.search(for: "search \(i)")
        }

        #expect(shopper.recentSearches.count == 10)
        #expect(shopper.recentSearches.first == "search 15")
        #expect(shopper.recentSearches.last == "search 6")
    }

    @Test("Clearing forgets everything, and the next search starts a fresh list")
    func clearing() {
        let shopper = Searcher()
        shopper.search(for: "mascara")

        shopper.clearHistory()

        #expect(shopper.recentSearches.isEmpty)

        shopper.search(for: "sofa")
        #expect(shopper.recentSearches == ["sofa"])
    }

    @Test("Recent searches are still there on the shopper's next visit")
    func survivesLeaving() {
        let shopper = Searcher()
        shopper.search(for: "mascara")
        shopper.search(for: "sofa")

        #expect(shopper.leaveAndComeBack().recentSearches == ["sofa", "mascara"])
    }
}

@MainActor
@Suite("Whose searches these are")
/// A guest searches too, so being nobody in particular is a shopper the history belongs to — which
/// is the difference between this and a wishlist, and it is asserted rather than asserted about.
struct WhoseSearchesTheseAreTests {
    @Test("A guest's searches are remembered for them, no account needed")
    func guestsAreRemembered() {
        let shopper = Searcher()

        shopper.search(for: "mascara")

        #expect(shopper.recentSearches == ["mascara"])
    }

    @Test("Signing in shows the shopper their own searches, not the ones made before")
    func signingInSwapsTheHistory() {
        let shopper = Searcher()
        shopper.search(for: "mascara")

        shopper.signIn(asUserId: 42)

        #expect(shopper.recentSearches.isEmpty)

        shopper.search(for: "sofa")
        #expect(shopper.recentSearches == ["sofa"])
    }

    @Test("Signing out hands the guest their own searches back")
    func signingOutRestoresTheGuestHistory() {
        let shopper = Searcher()
        shopper.search(for: "mascara")
        shopper.signIn(asUserId: 42)
        shopper.search(for: "sofa")

        shopper.signOut()

        #expect(shopper.recentSearches == ["mascara"])
    }

    @Test("Two shoppers do not see each other's searches")
    func searchesAreNotShared() {
        let shopper = Searcher(signedInAs: 1)
        shopper.search(for: "mascara")

        shopper.signIn(asUserId: 2)
        shopper.search(for: "sofa")

        #expect(shopper.recentSearches == ["sofa"])

        shopper.signIn(asUserId: 1)
        #expect(shopper.recentSearches == ["mascara"])
    }
}
