import Testing
import Tracking

@MainActor
@Suite("A shopper who has not agreed to be tracked is not")
struct AskingFirstTests {
    @Test("Nothing is reported until they are asked, and what they did while waiting is reported, in order, if they agree")
    func agreeing() async {
        let analyst = Analyst(shopperHasSaid: .notDetermined, andWillSay: .granted)

        analyst.screenIsViewed("home")
        analyst.buttonIsTapped("retry", on: "home")
        #expect(analyst.events.isEmpty)

        await analyst.shopperIsAskedAboutTracking()

        #expect(analyst.events.map(\.name) == ["screen_view", "select_content"])
    }

    @Test("A shopper who says no is never reported on, before or after")
    func declining() async {
        let analyst = Analyst(shopperHasSaid: .notDetermined, andWillSay: .denied)

        analyst.screenIsViewed("home")
        await analyst.shopperIsAskedAboutTracking()
        analyst.buttonIsTapped("retry", on: "home")
        analyst.appGoesToTheBackground()

        #expect(analyst.events.isEmpty)
    }
}
