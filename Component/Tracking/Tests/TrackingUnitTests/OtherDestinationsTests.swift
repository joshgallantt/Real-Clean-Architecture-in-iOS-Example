import Foundation
import Testing
import Tracking
import TrackingData
import TrackingTestSupport

@MainActor
@Suite("The same event, in each destination's own words")
struct OtherDestinationsTests {
    private let home = "home"
    private let beauty = TrackingContext.List(id: "home_carousel_beauty", name: "Beauty")

    private func json(_ log: SpyTrackingLog) -> [[String: Any]] {
        log.entries.map { (try? JSONSerialization.jsonObject(with: Data($0.utf8))) as? [String: Any] ?? [:] }
    }

    private func firebase(_ event: TrackingEvent) -> [String: Any] {
        let log = SpyTrackingLog()
        FirebaseDestination(log: log).send(event)
        return json(log)[0]
    }

    private func mParticle(_ event: TrackingEvent) -> [String: Any] {
        let log = SpyTrackingLog()
        MParticleDestination(log: log).send(event)
        return json(log)[0]
    }

    private func data(_ payload: [String: Any]) -> [String: Any] { payload["data"] as? [String: Any] ?? [:] }
    private func parameters(_ payload: [String: Any]) -> [String: Any] { payload["parameters"] as? [String: Any] ?? [:] }

    private var added: TrackingEvent {
        TrackingEvent(name: .productAdded, context: .screen(home), items: [anItem(7, price: 4.5, quantity: 2)], properties: [:])
    }

    private var purchase: TrackingEvent {
        TrackingEvent(
            name: .orderCompleted,
            context: .screen("bag"),
            items: [anItem(1, price: 9.99, quantity: 2)],
            properties: [.orderId: "A1B2"]
        )
    }

    // MARK: - Firebase

    @Test("Firebase logs a product added as add_to_cart, with Google's item keys")
    func firebaseAddToCart() {
        let call = firebase(added)

        #expect(call["logEvent"] as? String == "add_to_cart")
        #expect((parameters(call)["items"] as? [[String: Any]])?.first?["item_id"] as? String == "7")
        #expect((parameters(call)["value"] as? NSNumber)?.decimalValue == 9)
    }

    @Test("Firebase is told the screen once, on the screen view, and not again on what follows")
    func firebaseScreenName() {
        #expect(parameters(firebase(TrackingEvent.screenViewed(home)))["screen_name"] as? String == "home")
        #expect(parameters(firebase(added))["screen_name"] == nil)
    }

    @Test("Firebase logs an item seen in a list at once, as a list of that one item")
    func firebaseImpression() {
        let call = firebase(TrackingEvent.viewed("product", about: anItem(1, price: 1, quantity: 1), in: .list(home, beauty, index: 3)))

        #expect(call["logEvent"] as? String == "view_item_list")
        #expect((parameters(call)["items"] as? [[String: Any]])?.first?["index"] as? Int == 3)
    }

    // MARK: - mParticle

    @Test("mParticle takes a product added as a commerce event with an add_to_cart action")
    func mParticleAddToCart() {
        let event = mParticle(added)
        let action = data(event)["product_action"] as? [String: Any] ?? [:]

        #expect(event["event_type"] as? String == "commerce_event")
        #expect(action["action"] as? String == "add_to_cart")
        #expect((action["products"] as? [[String: Any]])?.first?["id"] as? String == "7")
        #expect(data(event)["currency_code"] as? String == "USD")
    }

    @Test("mParticle's purchase has the order id as its transaction and a total, not an attribute")
    func mParticlePurchase() {
        let event = mParticle(purchase)
        let action = data(event)["product_action"] as? [String: Any] ?? [:]

        #expect(action["action"] as? String == "purchase")
        #expect(action["transaction_id"] as? String == "A1B2")
        #expect((action["total_amount"] as? NSNumber)?.decimalValue == Decimal(string: "19.98"))
        #expect((data(event)["custom_attributes"] as? [String: Any])?["order_id"] == nil)
    }

    @Test("mParticle has no word for looking at a cart, so it goes as a custom event under its own name")
    func mParticleCartViewed() {
        let viewed = TrackingEvent(name: .cartViewed, context: .screen(home), items: [anItem(1, price: 1, quantity: 1)], properties: [:])
        let event = mParticle(viewed)

        #expect(event["event_type"] as? String == "custom_event")
        #expect(data(event)["event_name"] as? String == "Cart Viewed")
        #expect(data(event)["custom_event_type"] as? String == "other")
    }

    @Test("mParticle takes a screen view as its own event type")
    func mParticleScreen() {
        let event = mParticle(TrackingEvent.screenViewed(home))

        #expect(event["event_type"] as? String == "screen_view")
        #expect(data(event)["screen_name"] as? String == "home")
    }

    @Test("mParticle takes an item seen in a list as a product impression, and a tap on it as a click")
    func mParticleImpressionAndClick() {
        let item = anItem(1, price: 1, quantity: 1)
        let seen = mParticle(TrackingEvent.viewed("product", about: item, in: .list(home, beauty, index: 2)))
        let tapped = mParticle(TrackingEvent.tapped("product", about: item, in: .list(home, beauty, index: 2)))

        let impression = (data(seen)["product_impressions"] as? [[String: Any]])?.first
        #expect(impression?["product_impression_list"] as? String == "Beauty")
        #expect((impression?["products"] as? [[String: Any]])?.first?["position"] as? Int == 2)
        #expect((data(tapped)["product_action"] as? [String: Any])?["action"] as? String == "click")
    }

    @Test("A search is a custom event of mParticle's search kind, saying what was searched for")
    func mParticleSearch() {
        let searched = TrackingEvent(
            name: .productsSearched,
            context: .screen(home),
            items: [],
            properties: [.query: "lipstick"]
        )
        let event = mParticle(searched)

        #expect(data(event)["custom_event_type"] as? String == "search")
        #expect((data(event)["custom_attributes"] as? [String: Any])?["query"] as? String == "lipstick")
    }

    // MARK: - One name, three words

    @Test("Every destination hears the same event and says it its own way")
    func sameEventThreeWays() {
        let ga4Log = SpyTrackingLog()
        let ga4 = GA4Destination(log: ga4Log, batchWindow: .seconds(60))
        ga4.send(purchase)

        #expect(json(ga4Log)[0]["name"] as? String == "purchase")
        #expect(firebase(purchase)["logEvent"] as? String == "purchase")
        #expect((data(mParticle(purchase))["product_action"] as? [String: Any])?["action"] as? String == "purchase")
    }
}
