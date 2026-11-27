/// Evans, *Domain-Driven Design* (2003), Ch. 8 — Domain Events: something a shopper saw or did, said
/// in terms no analytics vendor owns — what it is called, where it happened, what it was about, and
/// whatever else is worth knowing.
///
/// One shape for every event. What tells two apart is the name, and the names are one closed list
/// — see `EventName`: whoever reports a step through the shop builds one of these with a name from
/// that list, and the data layer owns what each destination calls it.
///
/// It always has a `context`, so an event with nowhere to have happened cannot be built.
public struct TrackingEvent: Equatable, Sendable {
    public let name: EventName
    public let context: TrackingContext

    /// What it was about. Empty when it was about nothing a shopper could pick.
    public let items: [TrackedItem]

    /// Anything else worth knowing — see `PropertyKey`. A destination that calls it something else
    /// renames it, and one that has no use for it leaves it out.
    public let properties: [PropertyKey: String]

    public init(name: EventName, context: TrackingContext, items: [TrackedItem], properties: [PropertyKey: String]) {
        self.name = name
        self.context = context
        self.items = items
        self.properties = properties
    }

    // What any screen reports. Seeing and touching are different events, because a view is the
    // denominator of every rate a tap is the numerator of.

    public static func screenViewed(_ screen: String) -> TrackingEvent {
        TrackingEvent(name: .screenViewed, context: .screen(screen), items: [], properties: [:])
    }

    public static func viewed(_ element: String, in context: TrackingContext) -> TrackingEvent {
        TrackingEvent(.elementViewed, of: element, about: [], in: context)
    }

    public static func viewed(_ element: String, about item: TrackedItem, in context: TrackingContext) -> TrackingEvent {
        TrackingEvent(.elementViewed, of: element, about: [item], in: context)
    }

    public static func tapped(_ element: String, in context: TrackingContext) -> TrackingEvent {
        TrackingEvent(.elementSelected, of: element, about: [], in: context)
    }

    public static func tapped(_ element: String, about item: TrackedItem, in context: TrackingContext) -> TrackingEvent {
        TrackingEvent(.elementSelected, of: element, about: [item], in: context)
    }

    /// Something that happened to an element. Which element is the one thing all four say.
    private init(_ name: EventName, of element: String, about items: [TrackedItem], in context: TrackingContext) {
        self.init(name: name, context: context, items: items, properties: [.element: element])
    }
}
