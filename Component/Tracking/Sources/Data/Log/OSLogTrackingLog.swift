import os

/// Apple, *Logging* — `Logger`: the unified log, under a category of its own, so an event stream can
/// be watched in Console or Xcode with `category:Tracking`.
///
/// `.public` on purpose. An entry is a screen name, an element name and what was on the screen —
/// never who was looking at it — and a payload the log redacts to `<private>` is one nobody can check.
public struct OSLogTrackingLog: TrackingLog {
    private let logger: Logger

    public init(subsystem: String, category: String) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func write(_ entry: String) {
        logger.info("\(entry, privacy: .public)")
    }
}
