import Testing
import Tracking

@MainActor
@Suite("What a shopper sees and does is reported as it happened, in order, with where")
struct WatchingAShopperTests {
    private let beauty = TrackingContext.List(id: "home_carousel_beauty", name: "Beauty")

    @Test("A shopper looks at a carousel and the report says which cards they saw, in order")
    func aCarouselSeen() {
        let analyst = Analyst(shopperHasSaid: .granted, andWillSay: .granted)

        analyst.screenIsViewed("home")
        for (index, id) in [1, 2, 3].enumerated() { analyst.cardIsSeen(id, at: index, in: beauty, on: "home") }
        analyst.appGoesToTheBackground()

        let lists = analyst.events.filter { $0.name == "view_item_list" }
        #expect(lists.count == 1)
        #expect(lists[0].items.map { $0["index"] as? Int } == [0, 1, 2])
        #expect(lists[0].text("screen_name") == "home")
    }

    @Test("A card scrolled away from and back to is reported both times")
    func scrollingBack() {
        let analyst = Analyst(shopperHasSaid: .granted, andWillSay: .granted)

        analyst.cardIsSeen(1, at: 0, in: beauty, on: "home")
        analyst.cardIsSeen(1, at: 0, in: beauty, on: "home")
        analyst.appGoesToTheBackground()

        #expect(analyst.events.first { $0.name == "view_item_list" }?.items.count == 2)
    }

    @Test("A card seen and then tapped reads as seen, then tapped, at the same place")
    func seenThenTapped() {
        let analyst = Analyst(shopperHasSaid: .granted, andWillSay: .granted)

        analyst.cardIsSeen(1, at: 2, in: beauty, on: "home")
        analyst.cardIsTapped(1, at: 2, in: beauty, on: "home")

        #expect(analyst.events.map(\.name) == ["view_item_list", "select_item"])
        #expect(analyst.events[1].items[0]["index"] as? Int == 2)
    }
}
