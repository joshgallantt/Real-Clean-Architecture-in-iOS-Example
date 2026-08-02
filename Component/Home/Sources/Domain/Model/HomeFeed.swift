/// Evans, *Domain-Driven Design* (2003), Ch. 5 — Value Objects: the carousels one draw of Home
/// earned, held together because they were drawn together.
///
/// Evans, Ch. 10 — Assertions: a feed with no carousels cannot be built, so a draw that came back
/// with nothing and a draw that came back with a feed cannot be mistaken for one another.
public struct HomeFeed: Equatable, Sendable {
    public let carousels: [HomeCarousel]

    public init?(carousels: [HomeCarousel]) {
        guard !carousels.isEmpty else { return nil }
        self.carousels = carousels
    }
}
