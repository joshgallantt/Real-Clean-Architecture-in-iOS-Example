import Foundation
import BagData
import SearchHistoryData
import SessionData
import Order
import OrderData
import SettingsData
import TrackingData
import StockAlertData
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
    let settingsStore: SettingsStore
    let stockAlertStore: StockAlertStore
    let orderStore: OrderStore

    /// There is no processor to call, so the app ships a fake one the same way it ships
    /// `FakeAuthClient`. Swapping it for a real gateway is a change to this line.
    let paymentClient: PaymentService

    /// Where tracking events go. Firebase and mParticle send nothing yet — their SDKs are not
    /// linked — and the logger writes every event to the unified log, where it can be watched in
    /// Console under `category:Tracking`.
    let firebaseClient: FirebaseClient
    let mParticleClient: MParticleClient
    let trackingLogger: LoggerClient

    /// Who to ask whether the person may be tracked: the system's App Tracking Transparency prompt.
    /// Nothing reaches a client until they have agreed.
    let trackingConsent: TrackingConsentSource

    static let trackingSubsystem = "io.flixly.iPhone"

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
        settingsStore = FileSettingsStore()
        stockAlertStore = FileStockAlertStore()
        orderStore = FileOrderStore()
        paymentClient = FakePaymentService()
        firebaseClient = NoOpFirebaseClient()
        mParticleClient = NoOpMParticleClient()
        trackingLogger = OSLogLoggerClient(subsystem: Self.trackingSubsystem, category: "Tracking")
        trackingConsent = AppTrackingTransparencyConsentSource()
    }
}
