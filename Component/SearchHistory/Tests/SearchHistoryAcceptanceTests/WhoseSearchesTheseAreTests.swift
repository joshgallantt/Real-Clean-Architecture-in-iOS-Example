import Foundation
import Testing
import SearchHistory

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
