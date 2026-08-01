/// Evans, *Domain-Driven Design* (2003), Ch. 5 — Value Objects: the carousels one draw of Home
/// earned, held together because they were drawn together.
///
/// Evans, Ch. 10 — Assertions: a feed with no carousels cannot be built, so `loaded` cannot stand
/// for a screen with nothing on it.
struct HomeFeed: Equatable {
    let carousels: [HomeCarousel]

    init?(carousels: [HomeCarousel]) {
        guard !carousels.isEmpty else { return nil }
        self.carousels = carousels
    }
}
