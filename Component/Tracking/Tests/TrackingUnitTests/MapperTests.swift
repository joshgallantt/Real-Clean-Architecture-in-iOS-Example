import Testing
import Tracking
import TrackingTestSupport
@testable import TrackingData

@Suite("An event, in Firebase's words")
struct FirebaseEventMapperTests {
    private let mapper = FirebaseEventMapper()
    private let beauty = TrackingContext.List(id: "home_carousel_beauty", name: "Beauty")

    private func event(_ name: EventName, in context: TrackingContext, items: [TrackedItem], properties: [String: String]) -> TrackingEvent {
        TrackingEvent(name: name, context: context, items: items, properties: properties)
    }

    @Test("Every event goes under Google's name for it", arguments: [
        (EventName.screenViewed, "screen_view"), (.elementViewed, "view_content"), (.elementSelected, "select_content"),
        (.productViewed, "view_item"), (.productAdded, "add_to_cart"), (.productRemoved, "remove_from_cart"),
        (.cartViewed, "view_cart"), (.productAddedToWishlist, "add_to_wishlist"), (.checkoutStarted, "begin_checkout"),
        (.orderCompleted, "purchase"), (.productsSearched, "search"), (.signedIn, "login"), (.signedUp, "sign_up")
    ])
    func names(_ name: EventName, _ word: String) {
        #expect(mapper.map(event(name, in: .screen("home"), items: [], properties: [:])).name == word)
    }

    @Test("An item seen in a list is view_item_list and one tapped there is select_item, each saying where")
    func inAList() {
        let context = TrackingContext.list("home", beauty, index: 2)
        let seen = mapper.map(event(.elementViewed, in: context, items: [anItem(9, price: 12.5, quantity: 1)], properties: ["element": "product"]))
        let tapped = mapper.map(event(.elementSelected, in: context, items: [anItem(9, price: 12.5, quantity: 1)], properties: ["element": "product"]))

        #expect(seen.name == "view_item_list")
        #expect(tapped.name == "select_item")
        #expect(tapped.parameters["item_list_id"] == "home_carousel_beauty")
        #expect(tapped.parameters["item_list_name"] == "Beauty")
        #expect(tapped.parameters["index"] == nil)
        #expect(tapped.items[0]["index"] == "2")
        #expect(tapped.items[0]["item_list_id"] == "home_carousel_beauty")
    }

    @Test("Something in a list that is about no item still says where in the list it was")
    func elementInAList() {
        let tapped = mapper.map(event(.elementSelected, in: .list("home", beauty, index: 0), items: [], properties: ["element": "view_all"]))

        #expect(tapped.name == "select_content")
        #expect(tapped.parameters["index"] == "0")
    }

    @Test("Google's own keys replace ours where it has one, and any other key goes as it came")
    func parameterKeys() {
        let properties = ["element": "retry", "order_id": "A1B2", "query": "lipstick", "method": "email", "anything": "else"]
        let mapped = mapper.map(event(.cartViewed, in: .screen("bag"), items: [], properties: properties))

        #expect(mapped.parameters == [
            "content_id": "retry", "transaction_id": "A1B2", "search_term": "lipstick", "method": "email", "anything": "else"
        ])
    }

    @Test("The screen is named once, on the screen view, and not again on what follows")
    func screenName() {
        #expect(mapper.map(event(.screenViewed, in: .screen("home"), items: [], properties: [:])).parameters == ["screen_name": "home"])
        #expect(mapper.map(event(.productsSearched, in: .screen("home"), items: [], properties: [:])).parameters["screen_name"] == nil)
    }

    @Test("A product says its category, price and quantity; content says only its id and name")
    func items() {
        let mapped = mapper.map(event(
            .elementSelected,
            in: .screen("home"),
            items: [anItem(1, price: 9.99, quantity: 2), .content(id: "beauty", name: "Beauty")],
            properties: [:]
        ))

        #expect(mapped.items[0]["item_id"] == "1")
        #expect(mapped.items[0]["price"] == "9.99")
        #expect(mapped.items[0]["quantity"] == "2")
        #expect(Set(mapped.items[1].keys) == ["item_id", "item_name"])
    }

    @Test("What the products add up to goes with its currency")
    func value() {
        let mapped = mapper.map(event(.productAdded, in: .screen("product"), items: [anItem(3, price: 5, quantity: 2)], properties: [:]))

        #expect(mapped.parameters["value"] == "10")
        #expect(mapped.parameters["currency"] == "USD")
    }

    @Test("A string longer than Google keeps is cut to the 100 characters it does keep")
    func longText() {
        let long = String(repeating: "a", count: 150)
        let mapped = mapper.map(event(.screenViewed, in: .screen(long), items: [.content(id: "1", name: long)], properties: [:]))

        #expect(mapped.parameters["screen_name"]?.count == 100)
        #expect(mapped.items[0]["item_name"]?.count == 100)
    }
}

@Suite("An event, in mParticle's shape")
struct MParticleEventMapperTests {
    private let mapper = MParticleEventMapper()
    private let beauty = TrackingContext.List(id: "home_carousel_beauty", name: "Beauty")

    private func event(_ name: EventName, in context: TrackingContext, items: [TrackedItem], properties: [String: String]) -> TrackingEvent {
        TrackingEvent(name: name, context: context, items: items, properties: properties)
    }

    @Test("Every event is one of mParticle's three kinds", arguments: [
        (EventName.screenViewed, MParticleEventDTO.Kind.screenView),
        (.elementViewed, .custom(type: "other")), (.elementSelected, .custom(type: "navigation")),
        (.productViewed, .commerce(action: "view_detail")), (.productAdded, .commerce(action: "add_to_cart")),
        (.productRemoved, .commerce(action: "remove_from_cart")), (.cartViewed, .custom(type: "other")),
        (.productAddedToWishlist, .commerce(action: "add_to_wishlist")), (.checkoutStarted, .commerce(action: "checkout")),
        (.orderCompleted, .commerce(action: "purchase")), (.productsSearched, .custom(type: "search")),
        (.signedIn, .custom(type: "user_preference")), (.signedUp, .custom(type: "user_preference"))
    ])
    func kinds(_ name: EventName, _ kind: MParticleEventDTO.Kind) {
        #expect(mapper.map(event(name, in: .screen("home"), items: [], properties: [:])).kind == kind)
    }

    @Test("A screen view is named for its screen; anything else for the event's own title")
    func names() {
        #expect(mapper.map(event(.screenViewed, in: .screen("home"), items: [], properties: [:])).name == "home")
        #expect(mapper.map(event(.cartViewed, in: .screen("bag"), items: [], properties: [:])).name == "Cart Viewed")
    }

    @Test("An item seen in a list is an impression, and a tap on it a click, with its position")
    func inAList() {
        let context = TrackingContext.list("home", beauty, index: 2)
        let seen = mapper.map(event(.elementViewed, in: context, items: [anItem(1, price: 1, quantity: 1)], properties: [:]))
        let tapped = mapper.map(event(.elementSelected, in: context, items: [anItem(1, price: 1, quantity: 1)], properties: [:]))

        #expect(seen.kind == .commerce(action: "impression"))
        #expect(tapped.kind == .commerce(action: "click"))
        #expect(seen.attributes["list_name"] == "Beauty")
        #expect(tapped.products[0]["position"] == "2")
    }

    @Test("Properties go with the attributes as they came, beside where it happened and what it was worth")
    func attributes() {
        let purchase = event(.orderCompleted, in: .screen("bag"), items: [anItem(1, price: 9.99, quantity: 2)], properties: ["order_id": "A1B2"])

        #expect(mapper.map(purchase).attributes == [
            "order_id": "A1B2", "screen_name": "bag", "total_amount": "19.98", "currency_code": "USD"
        ])
    }

    @Test("Only products are products: something that is not one is left out")
    func products() {
        let mapped = mapper.map(event(
            .productAdded,
            in: .screen("home"),
            items: [anItem(7, price: 4.5, quantity: 2), .content(id: "beauty", name: "Beauty")],
            properties: [:]
        ))

        #expect(mapped.products.map { $0["id"] } == ["7"])
        #expect(mapped.products[0]["quantity"] == "2")
    }
}

@Suite("An event, as a line in the log")
struct LoggerEventMapperTests {
    private let mapper = LoggerEventMapper()

    @Test("A line says what happened, where, and anything else worth knowing, in the same order every time")
    func line() {
        let event = TrackingEvent(
            name: .orderCompleted,
            context: .list("bag", TrackingContext.List(id: "bag", name: "Bag"), index: 1),
            items: [anItem(3, price: 5, quantity: 2), .content(id: "beauty", name: "Beauty")],
            properties: ["order_id": "A1B2", "method": "card"]
        )

        #expect(mapper.map(event) == "Order Completed | screen=bag | list=bag[1] | method=card | order_id=A1B2 | items=3 x2 @5 USD,beauty")
    }

    @Test("A screen view is its name and its screen, and nothing else")
    func screenView() {
        let event = TrackingEvent(name: .screenViewed, context: .screen("home"), items: [], properties: [:])

        #expect(mapper.map(event) == "Screen Viewed | screen=home")
    }
}

@Suite("What an event is worth")
struct EventValueTests {
    @Test("Each product's price times how many, added up")
    func total() {
        let event = TrackingEvent(name: .cartViewed, context: .screen("bag"), items: [anItem(1, price: 9.99, quantity: 2), anItem(2, price: 5, quantity: 1)], properties: [:])

        #expect(event.value?.amount == 24.98)
    }

    @Test("Nothing when it is about nothing, or about something that is not a product")
    func nothing() {
        let empty = TrackingEvent(name: .cartViewed, context: .screen("bag"), items: [], properties: [:])
        let mixed = TrackingEvent(name: .cartViewed, context: .screen("bag"), items: [anItem(1, price: 1, quantity: 1), .content(id: "a", name: "A")], properties: [:])

        #expect(empty.value == nil)
        #expect(mixed.value == nil)
    }
}
