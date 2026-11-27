/// Whether a view coming into view is the shopper arriving, or SwiftUI passing through.
///
/// Pushing onto a `NavigationStack` takes the screen underneath away, puts it straight back, and
/// takes it away again once the push has finished animating — so the screen being left "appears"
/// in the middle of leaving, and so does every card on it. Measured on iOS 27.2, the false arrival
/// comes within a hundredth of a second of the departure before it. Nobody leaves a screen and
/// comes back to it that fast, so an arrival that close behind a departure is not counted.
struct Presence {
    private enum Departure {
        case none
        case at(ContinuousClock.Instant)
    }

    /// Ten times the gap measured, and still far shorter than anything a shopper can do.
    private let tooSoonToBeReal = Duration.milliseconds(100)

    private var lastDeparture = Departure.none

    mutating func left(at instant: ContinuousClock.Instant) {
        lastDeparture = .at(instant)
    }

    func isArrival(at instant: ContinuousClock.Instant) -> Bool {
        switch lastDeparture {
        case .none: true
        case .at(let departed): departed.duration(to: instant) >= tooSoonToBeReal
        }
    }
}
