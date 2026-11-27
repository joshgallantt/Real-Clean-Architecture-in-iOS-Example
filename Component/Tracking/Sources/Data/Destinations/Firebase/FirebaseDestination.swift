import Tracking

/// Firebase Analytics, by its SDK. It sends nothing — each call it would make is written to its log
/// instead, so linking the SDK is a change to this file and nothing else.
///
/// It holds nothing back: the SDK does its own batching.
@MainActor
public final class FirebaseDestination: TrackingDestination {
    private let log: TrackingLog
    private let mapper = FirebaseEventMapper()

    public init(log: TrackingLog) {
        self.log = log
    }

    public func send(_ event: TrackingEvent) {
        if event.name == .elementViewed, let item = event.items.first, case .inList(let list, let index) = event.context.placement {
            log.write(mapper.payload(forItemSeen: item, at: index, in: list).line)
        } else {
            log.write(mapper.payload(for: event).line)
        }
    }

    /// Nothing is held, so there is nothing to send.
    public func flush() {}
}
