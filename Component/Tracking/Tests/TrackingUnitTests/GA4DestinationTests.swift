import Foundation
import Testing
import Tracking
import TrackingData
import TrackingTestSupport

@MainActor
@Suite("What reaches the log, in GA4's shape")
struct GA4DestinationTests {
    private let home = "home"
    private let beauty = TrackingContext.List(id: "home_carousel_beauty", name: "Beauty")

    private func written(_ events: TrackingEvent...) -> [[String: Any]] {
        let log = SpyTrackingLog()
        let destination = GA4Destination(log: log, batchWindow: .seconds(60))
        events.forEach(destination.send)
        destination.flush()
        return log.entries.map { (try? JSONSerialization.jsonObject(with: Data($0.utf8))) as? [String: Any] ?? [:] }
    }

    private func params(_ event: [String: Any]) -> [String: Any] { event["params"] as? [String: Any] ?? [:] }
    private func items(_ event: [String: Any]) -> [[String: Any]] { params(event)["items"] as? [[String: Any]] ?? [] }

    @Test("A screen view is screen_view, with the screen's name")
    func screenView() {
        let event = written(TrackingEvent.screenViewed(home))[0]

        #expect(event["name"] as? String == "screen_view")
        #expect(params(event)["screen_name"] as? String == "home")
    }

    @Test("A tap on the screen is select_content, with the element's name as content_id")
    func tapOnScreen() {
        let event = written(TrackingEvent.tapped("retry", in: .screen(home)))[0]

        #expect(event["name"] as? String == "select_content")
        #expect(params(event)["content_id"] as? String == "retry")
    }

    @Test("Seeing an element is view_content, with the same parameters a tap on it would have")
    func viewAndTapShareParameters() {
        let seen = params(written(TrackingEvent.viewed("in_the_bag", in: .screen(home)))[0])
        let tapped = params(written(TrackingEvent.tapped("in_the_bag", in: .screen(home)))[0])

        #expect(NSDictionary(dictionary: seen) == NSDictionary(dictionary: tapped))
    }

    @Test("A tap on a product in a list is select_item, its position on the item and the list on both")
    func tapInAList() {
        let event = written(TrackingEvent.tapped("product", about: anItem(9, price: 12.5, quantity: 1), in: .list(home, beauty, index: 2)))[0]

        #expect(event["name"] as? String == "select_item")
        #expect(params(event)["item_list_id"] as? String == "home_carousel_beauty")
        #expect(params(event)["index"] == nil)
        #expect(items(event)[0]["index"] as? Int == 2)
        #expect(items(event)[0]["item_list_id"] as? String == "home_carousel_beauty")
        #expect(params(event)["currency"] as? String == "USD")
    }

    @Test("A tap about a product that is not in a list is select_content about that product")
    func tapOffAList() {
        let event = written(TrackingEvent.tapped("wishlist_on", about: anItem(4, price: 1, quantity: 1), in: .screen(home)))[0]

        #expect(event["name"] as? String == "select_content")
        #expect(params(event)["content_id"] as? String == "wishlist_on")
        #expect(items(event)[0]["item_id"] as? String == "4")
    }

    @Test("Something in a list that is about no item still says where in the list it was")
    func elementInAList() {
        let event = written(TrackingEvent.tapped("view_all", in: .list(home, beauty, index: 0)))[0]

        #expect(params(event)["index"] as? Int == 0)
    }

    @Test("A product says its category, price and quantity; content says only its id and name")
    func productAndContent() {
        let product = items(written(TrackingEvent.tapped("p", about: anItem(1, price: 9.99, quantity: 2), in: .screen(home)))[0])[0]
        let content = items(written(TrackingEvent.tapped("category", about: .content(id: "beauty", name: "Beauty"), in: .screen(home)))[0])[0]

        #expect((product["price"] as? NSNumber)?.decimalValue == Decimal(string: "9.99"))
        #expect(product["quantity"] as? Int == 2)
        #expect(Set(content.keys) == ["item_id", "item_name"])
    }

    @Test("A step through the shop says where it was taken, what it was about and what that was worth")
    func stepThroughTheShop() {
        let added = TrackingEvent(name: .productAdded, context: .screen("product"), items: [anItem(3, price: 5, quantity: 2)], properties: [:])
        let event = written(added)[0]

        #expect(event["name"] as? String == "add_to_cart")
        #expect(params(event)["screen_name"] as? String == "product")
        #expect(items(event)[0]["item_id"] as? String == "3")
        #expect((params(event)["value"] as? NSNumber)?.decimalValue == 10)
        #expect(params(event)["currency"] as? String == "USD")
    }

    @Test("A string longer than GA4 keeps is cut to the 100 characters it does keep")
    func longText() {
        let long = String(repeating: "a", count: 150)
        let event = written(TrackingEvent.tapped("p", about: .content(id: "1", name: long), in: .screen(long)))[0]

        #expect((params(event)["screen_name"] as? String)?.count == 100)
        #expect((items(event)[0]["item_name"] as? String)?.count == 100)
    }

    @Test("The same event is written as the same line every time")
    func sameLine() {
        let log = SpyTrackingLog()
        let destination = GA4Destination(log: log, batchWindow: .seconds(60))
        let toggle = TrackingEvent.tapped("push_notifications_on", in: .screen("settings"))

        destination.send(toggle)
        destination.send(toggle)

        #expect(log.entries[0] == log.entries[1])
        #expect(log.entries[0] == #"{"name":"select_content","params":{"content_id":"push_notifications_on","screen_name":"settings"}}"#)
    }
}

@MainActor
@Suite("Items seen in a list reach GA4 together")
struct GA4BatchingTests {
    private let home = "home"
    private let beauty = TrackingContext.List(id: "beauty", name: "Beauty")

    private func seen(_ id: Int, at index: Int, in list: TrackingContext.List) -> TrackingEvent {
        TrackingEvent.viewed("product", about: anItem(id, price: 1, quantity: 1), in: .list(home, list, index: index))
    }

    private func names(_ log: SpyTrackingLog) -> [String] {
        log.entries.compactMap { ((try? JSONSerialization.jsonObject(with: Data($0.utf8))) as? [String: Any])?["name"] as? String }
    }

    @Test("Cards seen in one list are held back and written as one view_item_list, in order")
    func batched() {
        let log = SpyTrackingLog()
        let destination = GA4Destination(log: log, batchWindow: .seconds(60))

        destination.send(seen(1, at: 0, in: beauty))
        destination.send(seen(2, at: 1, in: beauty))
        #expect(log.entries.isEmpty)
        destination.flush()

        #expect(names(log) == ["view_item_list"])
        #expect(log.entries[0].contains(#""index":0"#) && log.entries[0].contains(#""index":1"#))
    }

    @Test("Two lists seen together are two view_item_list events")
    func onePerList() {
        let log = SpyTrackingLog()
        let destination = GA4Destination(log: log, batchWindow: .seconds(60))

        destination.send(seen(1, at: 0, in: beauty))
        destination.send(seen(2, at: 0, in: TrackingContext.List(id: "toys", name: "Toys")))
        destination.flush()

        #expect(names(log) == ["view_item_list", "view_item_list"])
    }

    @Test("Anything else sends what was held first, so the log reads in the order it happened")
    func orderKept() {
        let log = SpyTrackingLog()
        let destination = GA4Destination(log: log, batchWindow: .seconds(60))

        destination.send(seen(1, at: 0, in: beauty))
        destination.send(TrackingEvent.tapped("product", about: anItem(1, price: 1, quantity: 1), in: .list(home, beauty, index: 0)))

        #expect(names(log) == ["view_item_list", "select_item"])
    }

    @Test("A list that reaches GA4's 200 items is sent then and there")
    func capAt200() {
        let log = SpyTrackingLog()
        let destination = GA4Destination(log: log, batchWindow: .seconds(60))

        for index in 0..<201 { destination.send(seen(index, at: index, in: beauty)) }
        #expect(names(log) == ["view_item_list"])

        destination.flush()
        #expect(names(log) == ["view_item_list", "view_item_list"])
    }

    @Test("Once the list has been quiet for the batch window, what was held is sent on its own")
    func sentAfterTheWindow() async throws {
        let log = SpyTrackingLog()
        let destination = GA4Destination(log: log, batchWindow: .milliseconds(20))

        destination.send(seen(1, at: 0, in: beauty))
        try await Task.sleep(for: .milliseconds(300))

        #expect(names(log) == ["view_item_list"])
    }
}
