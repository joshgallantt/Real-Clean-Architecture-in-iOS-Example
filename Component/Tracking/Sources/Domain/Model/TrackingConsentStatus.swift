/// Whether the person has said they may be tracked. Three states, because "not asked yet" and
/// "said no" are different instructions: the first is a reason to wait, the second to forget.
public enum TrackingConsentStatus: Equatable, Sendable {
    case notDetermined
    case granted
    case denied
}
