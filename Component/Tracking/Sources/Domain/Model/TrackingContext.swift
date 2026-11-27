/// Where something happened. There is always a screen; a position in a list is there only for the
/// things that are in one.
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

    /// A place in a list. A position without a list means nothing, so the two travel together.
    /// The position counts from the top: the first card is at 0.
    public struct ListPosition: Equatable, Hashable, Sendable {
        public let list: List
        public let index: Int

        public init(list: List, index: Int) {
            self.list = list
            self.index = index
        }
    }

    public let screen: String

    /// Where in a list it was, for the things that are in one. Most are not.
    public let listPosition: ListPosition?

    public init(screen: String, listPosition: ListPosition?) {
        self.screen = screen
        self.listPosition = listPosition
    }

    public static func screen(_ screen: String) -> TrackingContext {
        TrackingContext(screen: screen, listPosition: nil)
    }

    public static func list(_ screen: String, _ list: List, index: Int) -> TrackingContext {
        TrackingContext(screen: screen, listPosition: ListPosition(list: list, index: index))
    }
}
