import Tracking

/// The Firebase SDK's shape: a call to `Analytics.logEvent(_:parameters:)`. Google's words, the
/// same ones GA4 uses.
///
/// It leaves `screen_name` off everything but the screen view itself. The SDK remembers the last
/// screen it was told about and attaches it to every event after, so sending it again would only
/// be a second copy to keep in step with the first.
struct FirebaseEventMapper {
    private let google = GoogleAnalyticsEventMapper()

    func payload(for event: TrackingEvent) -> JSONValue {
        var parameters = google.parameters(of: event)
        if event.name == .screenViewed {
            parameters[GoogleAnalyticsVocabulary.Parameter.screenName.rawValue] = google.screenName(of: event)
        }
        return call(google.name(of: event), parameters)
    }

    /// The SDK batches and uploads on its own schedule, so an item seen in a list is logged at
    /// once, as a `view_item_list` of that one item.
    func payload(forItemSeen item: TrackedItem, at index: Int, in list: TrackingContext.List) -> JSONValue {
        call(
            GoogleAnalyticsVocabulary.ListEvent.viewItemList.rawValue,
            google.itemListViewed([google.item(item, at: index, in: list)], in: list)
        )
    }

    private func call(_ name: String, _ parameters: [String: JSONValue]) -> JSONValue {
        .object(["logEvent": .string(name), "parameters": .object(parameters)])
    }
}
