/// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: what Home is
/// showing, as one fact with three cases rather than three properties a reader has to combine.
///
/// A shop that cannot be reached and a shop with nothing to draw are the same case here: either
/// way Home has nothing to show and offers to try again.
enum HomeScreenState: Equatable {
    case loading
    case loaded(HomeFeed)
    case error
}
