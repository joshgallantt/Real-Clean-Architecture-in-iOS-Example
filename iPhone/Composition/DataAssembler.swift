import Foundation
import BagData
import SearchHistoryData
import SessionData
import WishlistData

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: the first of the composition
/// root's three phases. Every concrete store and client the app runs on is named here, and the
/// later phases receive them already built.
///
/// Martin, Ch. 30 — The Database Is a Detail: a file on disk, `UserDefaults`, and how long a
/// sign-in lasts are decisions, not facts. Naming them together makes the whole set of them
/// readable at once, and replacing any one of them a change to this file.
///
/// Martin, Ch. 22 — The Clean Architecture: the outermost ring. Nothing inward knows these types
/// exist; each is reached only through the protocol its component declared.
@MainActor
struct DataAssembler {
    let sessionStore: SessionStore
    let authClient: AuthClient
    let searchHistoryStore: SearchHistoryStore
    let wishlistStore: WishlistStore
    let bagStore: BagStore

    /// A sign-in outlives the app being closed, but not indefinitely.
    static let signInLasts: TimeInterval = 60 * 60 * 24 * 7

    init(defaults: UserDefaults = .standard) {
        sessionStore = DefaultSessionStore(defaults: defaults)
        authClient = FakeAuthClient(
            userStore: UserDefaultsUserStore(defaults: defaults),
            tokenLifetime: Self.signInLasts
        )
        searchHistoryStore = UserDefaultsSearchHistoryStore(defaults: defaults)
        wishlistStore = FileWishlistStore()
        bagStore = FileBagStore()
    }
}
