import AppTrackingTransparency
import Tracking

/// Apple, *App Tracking Transparency*: the system prompt, and the answer the person gave it.
///
/// "Restricted" — tracking switched off for this device by a parent or an administrator — is a no
/// that the person was never asked for, and is treated as one.
///
/// The prompt only appears while the app is active, and only the first time; after that,
/// `requestTrackingAuthorization` returns at once with the answer already on record.
@MainActor
public final class AppTrackingTransparencyConsentSource: TrackingConsentSource {
    public init() {}

    public var status: TrackingConsentStatus {
        Self.status(from: ATTrackingManager.trackingAuthorizationStatus)
    }

    public func request() async -> TrackingConsentStatus {
        Self.status(from: await ATTrackingManager.requestTrackingAuthorization())
    }

    private static func status(from authorization: ATTrackingManager.AuthorizationStatus) -> TrackingConsentStatus {
        switch authorization {
        case .authorized: .granted
        case .notDetermined: .notDetermined
        case .denied, .restricted: .denied
        @unknown default: .denied
        }
    }
}
