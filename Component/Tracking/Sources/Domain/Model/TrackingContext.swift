/// Where something happened. There is always a screen; whether it was also at a position in a list
/// is the part that varies, so that is the part with cases.
///
/// A view that was never told its screen reports an empty screen name. That is not a place, so
/// `DefaultTrackEventUseCase` does not report it.
///
/// A screen is its name and nothing more, so it is a `String`. A list is two things that travel
/// together, so it is a type — and it lives here because this is the only place a list is used.
public struct TrackingContext: Equatable, Hashable, Sendable {
    /// A list a shopper can scroll: an id that outlives a retitle, and the title it had when seen.
    public struct List: Equatable, Hashable, Sendable {
        public let id: String
        public let name: String

        public init(id: String, name: String) {
            self.id = id
            self.name = name
        }
    }

    /// Where on its screen. A position without a list means nothing, so the two travel together.
    /// The position counts from the top: the first card is at 0.
    public enum Placement: Equatable, Hashable, Sendable {
        case onScreen
        case inList(List, index: Int)
    }

    public let screen: String
    public let placement: Placement

    public init(screen: String, placement: Placement) {
        self.screen = screen
        self.placement = placement
    }

    public static func screen(_ screen: String) -> TrackingContext {
        TrackingContext(screen: screen, placement: .onScreen)
    }

    public static func list(_ screen: String, _ list: List, index: Int) -> TrackingContext {
        TrackingContext(screen: screen, placement: .inList(list, index: index))
    }
}
