import Foundation
import Tracking

/// Google Analytics 4, by its Measurement Protocol. It sends nothing — each payload it would post
/// is written to its log instead, one sorted-key JSON line each, so pointing it at the real endpoint
/// is a change to what it writes to and nothing else.
///
/// Items seen in a list are held back and sent together, one `view_item_list` per list. A carousel
/// coming on screen is five cards appearing within a frame of each other, and five requests for it
/// would be five times the traffic and a report GA4 has to stitch back into one. They go when the
/// list goes quiet for `batchWindow`, when a list reaches GA4's 200 items, or — so the log still
/// reads in the order things happened — the moment anything else is sent.
///
/// Batching is this destination's decision, because it is this one that pays per request.
@MainActor
public final class GA4Destination: TrackingDestination {
    private struct Batch {
        let first: TrackingEvent
        let list: TrackingContext.List
        var items: [JSONValue]
    }

    public static let maxItemsPerEvent = 200

    private let log: TrackingLog
    private let batchWindow: Duration
    private let mapper = GA4EventMapper()
    private var batches: [Batch] = []
    private var scheduledFlush: Task<Void, Never>?

    public init(log: TrackingLog, batchWindow: Duration) {
        self.log = log
        self.batchWindow = batchWindow
    }

    public func send(_ event: TrackingEvent) {
        guard event.name == .elementViewed, let item = event.items.first, case .inList(let list, let index) = event.context.placement else {
            flush()
            log.write(mapper.payload(for: event).line)
            return
        }
        hold(mapper.item(item, at: index, in: list), in: list, like: event)
    }

    public func flush() {
        scheduledFlush?.cancel()
        scheduledFlush = nil
        let ready = batches
        batches = []
        ready.forEach(write)
    }

    private func hold(_ item: JSONValue, in list: TrackingContext.List, like seen: TrackingEvent) {
        let belongs: (Batch) -> Bool = {
            $0.list == list && $0.first.context.screen == seen.context.screen && $0.first.properties == seen.properties
        }
        if let at = batches.firstIndex(where: belongs) {
            batches[at].items.append(item)
            if batches[at].items.count >= Self.maxItemsPerEvent {
                write(batches.remove(at: at))
            }
        } else {
            batches.append(Batch(first: seen, list: list, items: [item]))
        }
        scheduleFlush()
    }

    private func scheduleFlush() {
        guard scheduledFlush == nil else { return }
        let window = batchWindow
        scheduledFlush = Task { [weak self] in
            try? await Task.sleep(for: window)
            guard !Task.isCancelled else { return }
            self?.flush()
        }
    }

    private func write(_ batch: Batch) {
        log.write(mapper.itemListViewed(batch.items, in: batch.list, like: batch.first).line)
    }
}
