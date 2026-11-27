import os

/// Apple, *Logging* — `Logger`: the unified log, under a category of its own, so the event stream
/// can be watched in Console or Xcode with `category:Tracking`.
///
/// `.public` on purpose. A line is a screen name, an element name and what was on the screen —
/// never who was looking at it — and a line the log redacts to `<private>` is one nobody can check.
public struct OSLogLoggerClient: LoggerClient {
    private let logger: Logger

    public init(subsystem: String, category: String) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func log(_ line: String) {
        logger.info("\(line, privacy: .public)")
    }
}
