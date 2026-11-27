import Foundation
import Testing
import Tracking
import TrackingData
import TrackingTestSupport

@MainActor
@Suite("Every destination has its own word for every event and every property")
struct VocabularyTests {
    private let home = "home"
    private let beauty = TrackingContext.List(id: "home_carousel_beauty", name: "Beauty")

    // What each destination is expected to say, typed here by hand rather than read back from a
    // vocabulary. Every case is looked up, so an event or a property with no line here fails.

    private let googleNames: [EventName: String] = [
        .screenViewed: "screen_view",
        .elementViewed: "view_content",
        .elementSelected: "select_content",
        .productViewed: "view_item",
        .productAdded: "add_to_cart",
        .productRemoved: "remove_from_cart",
        .cartViewed: "view_cart",
        .productAddedToWishlist: "add_to_wishlist",
        .checkoutStarted: "begin_checkout",
        .orderCompleted: "purchase",
        .productsSearched: "search",
        .signedIn: "login",
        .signedUp: "sign_up"
    ]

    /// mParticle's shape for each event, as the words that tell one shape from another: its event
    /// type, then the action of a commerce event, or the name and kind of a custom one.
    private let mParticleShapes: [EventName: [String]] = [
        .screenViewed: ["screen_view"],
        .elementViewed: ["custom_event", "Element Viewed", "other"],
        .elementSelected: ["custom_event", "Element Selected", "navigation"],
        .productViewed: ["commerce_event", "view_detail"],
        .productAdded: ["commerce_event", "add_to_cart"],
        .productRemoved: ["commerce_event", "remove_from_cart"],
        .cartViewed: ["custom_event", "Cart Viewed", "other"],
        .productAddedToWishlist: ["commerce_event", "add_to_wishlist"],
        .checkoutStarted: ["commerce_event", "checkout"],
        .orderCompleted: ["commerce_event", "purchase"],
        .productsSearched: ["custom_event", "Products Searched", "search"],
        .signedIn: ["custom_event", "Signed In", "user_preference"],
        .signedUp: ["custom_event", "Signed Up", "user_preference"]
    ]

    private let googleKeys: [PropertyKey: String] = [
        .element: "content_id",
        .orderId: "transaction_id",
        .query: "search_term",
        .method: "method"
    ]

    /// Where on a purchase mParticle keeps each property, as the field and the key inside it.
    private let mParticlePlaces: [PropertyKey: String] = [
        .element: "custom_attributes.element",
        .orderId: "product_action.transaction_id",
        .query: "custom_attributes.query",
        .method: "custom_attributes.method"
    ]

    private func named(_ name: EventName) -> TrackingEvent {
        TrackingEvent(name: name, context: .screen(home), items: [anItem(1, price: 1, quantity: 1)], properties: [:])
    }

    private func written(_ log: SpyTrackingLog) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: Data((log.entries.first ?? "").utf8))) as? [String: Any] ?? [:]
    }

    /// What GA4 is sent, once anything it held back has gone.
    private func ga4(_ event: TrackingEvent) -> [String: Any] {
        let log = SpyTrackingLog()
        let destination = GA4Destination(log: log, batchWindow: .seconds(60))
        destination.send(event)
        destination.flush()
        return written(log)
    }

    private func firebase(_ event: TrackingEvent) -> [String: Any] {
        let log = SpyTrackingLog()
        FirebaseDestination(log: log).send(event)
        return written(log)
    }

    private func mParticle(_ event: TrackingEvent) -> [String: Any] {
        let log = SpyTrackingLog()
        MParticleDestination(log: log).send(event)
        return written(log)
    }

    private func data(_ payload: [String: Any]) -> [String: Any] { payload["data"] as? [String: Any] ?? [:] }

    /// The words that tell one mParticle shape from another, in the order `mParticleShapes` gives them.
    private func shape(of payload: [String: Any]) -> [String] {
        let action = data(payload)["product_action"] as? [String: Any] ?? [:]
        let words = [
            payload["event_type"],
            action["action"],
            data(payload)["event_name"],
            data(payload)["custom_event_type"]
        ]
        return words.compactMap { $0 as? String }
    }

    /// Everywhere in what mParticle was sent that a value turned up, as the field and the key inside it.
    private func places(of value: String, in payload: [String: Any]) -> [String] {
        var places: [String] = []
        for field in ["custom_attributes", "product_action"] {
            let kept = data(payload)[field] as? [String: Any] ?? [:]
            for (key, text) in kept where text as? String == value {
                places.append("\(field).\(key)")
            }
        }
        return places
    }

    // MARK: - Google

    @Test("GA4 hears every event under Google's name for it", arguments: EventName.allCases)
    func ga4EventName(_ name: EventName) throws {
        let word = try #require(googleNames[name])

        #expect(ga4(named(name))["name"] as? String == word)
    }

    @Test("Firebase logs every event under the name GA4 hears it by, because both are Google", arguments: EventName.allCases)
    func firebaseEventName(_ name: EventName) throws {
        let word = try #require(googleNames[name])

        #expect(firebase(named(name))["logEvent"] as? String == word)
    }

    @Test("An item seen in a list is view_item_list to GA4 and to Firebase, whatever seeing anything else is called")
    func itemSeenInAList() {
        let seen = TrackingEvent.viewed("product", about: anItem(1, price: 1, quantity: 1), in: .list(home, beauty, index: 0))

        #expect(ga4(seen)["name"] as? String == "view_item_list")
        #expect(firebase(seen)["logEvent"] as? String == "view_item_list")
    }

    @Test("A tap on an item in a list is select_item to GA4 and to Firebase, whatever a tap on anything else is called")
    func itemTappedInAList() {
        let tapped = TrackingEvent.tapped("product", about: anItem(1, price: 1, quantity: 1), in: .list(home, beauty, index: 0))

        #expect(ga4(tapped)["name"] as? String == "select_item")
        #expect(firebase(tapped)["logEvent"] as? String == "select_item")
    }

    @Test("GA4 hears every property under Google's key for it, and under no other", arguments: PropertyKey.allCases)
    func ga4ParameterKey(_ key: PropertyKey) throws {
        let word = try #require(googleKeys[key])
        let event = TrackingEvent(name: .cartViewed, context: .screen(home), items: [], properties: [key: "said"])
        let params = ga4(event)["params"] as? [String: Any] ?? [:]

        #expect(params[word] as? String == "said")
        #expect(Set(params.keys) == [word, "screen_name"])
    }

    // MARK: - mParticle

    @Test(
        "mParticle takes every event in a shape of its own: a screen view, a commerce event with an action, or a custom event of one of its kinds under the event's own title",
        arguments: EventName.allCases
    )
    func mParticleEventShape(_ name: EventName) throws {
        let expected = try #require(mParticleShapes[name])

        #expect(shape(of: mParticle(named(name))) == expected)
    }

    @Test(
        "mParticle keeps every property in one place: among the custom attributes under the property's own key, or in the field a purchase has for it",
        arguments: PropertyKey.allCases
    )
    func mParticlePropertyPlace(_ key: PropertyKey) throws {
        let expected = try #require(mParticlePlaces[key])
        let purchase = TrackingEvent(name: .orderCompleted, context: .screen(home), items: [anItem(1, price: 1, quantity: 1)], properties: [key: "said"])

        #expect(places(of: "said", in: mParticle(purchase)) == [expected])
    }
}
