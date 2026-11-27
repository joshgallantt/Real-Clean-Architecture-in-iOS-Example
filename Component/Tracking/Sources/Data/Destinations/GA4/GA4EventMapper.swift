import Tracking

/// GA4's Measurement Protocol shape: `{"name": …, "params": {…}}`. Every event carries
/// `screen_name` as a parameter, because a request to the protocol knows nothing about the app's
/// state — there is no SDK on the other end remembering which screen was last viewed.
struct GA4EventMapper {
    private let google = GoogleAnalyticsEventMapper()

    func payload(for event: TrackingEvent) -> JSONValue {
        payload(named: google.name(of: event), on: event, google.parameters(of: event))
    }

    func item(_ item: TrackedItem, at index: Int, in list: TrackingContext.List) -> JSONValue {
        google.item(item, at: index, in: list)
    }

    func itemListViewed(_ items: [JSONValue], in list: TrackingContext.List, like seen: TrackingEvent) -> JSONValue {
        payload(named: GoogleAnalyticsVocabulary.ListEvent.viewItemList.rawValue, on: seen, google.itemListViewed(items, in: list))
    }

    private func payload(named name: String, on event: TrackingEvent, _ parameters: [String: JSONValue]) -> JSONValue {
        var params = parameters
        params[GoogleAnalyticsVocabulary.Parameter.screenName.rawValue] = google.screenName(of: event)
        return .object(["name": .string(name), "params": .object(params)])
    }
}
