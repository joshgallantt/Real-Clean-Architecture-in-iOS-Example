/// Where a destination writes an event once it is in its vendor's shape, for as long as it sends
/// nothing. Told text, so it cannot have an opinion about what an event is.
///
/// A data-layer contract, declared beside the destinations because they are all that writes to
/// one: the composition root hands each the unified log, and a test hands it a log it can read back.
public protocol TrackingLog: Sendable {
    func write(_ entry: String)
}
