import Testing
import Tracking
import TrackingTestSupport

@MainActor
@Suite("The rules about what is worth reporting")
struct TrackingRulesTests {
    private let repository = SpyTrackingRepository()
    private let home = "home"
    private let beauty = TrackingContext.List(id: "home_carousel_beauty", name: "Beauty")
    private let card = "product"

    private var trackEvent: TrackEventUseCase { DefaultTrackEventUseCase(repository: repository) }
    private var screenView: TrackScreenViewUseCase { DefaultTrackScreenViewUseCase(trackEvent: trackEvent) }
    private var view: TrackElementViewUseCase { DefaultTrackElementViewUseCase(trackEvent: trackEvent) }
    private var tap: TrackElementInteractionUseCase { DefaultTrackElementInteractionUseCase(trackEvent: trackEvent) }

    private func item(_ id: Int) -> TrackedItem { anItem(id, price: 9.99, quantity: 1) }
    private var sightings: Int { repository.events.filter { $0.name == .elementViewed }.count }

    @Test("A screen coming into view is that screen viewed")
    func screenViewed() {
        screenView(home)

        #expect(repository.events == [.screenViewed(home)])
    }

    @Test("Seeing and touching, about an item or not, are four different events")
    func fourEvents() {
        view("saved", in: .screen(home))
        view(card, about: item(1), in: .screen(home))
        tap("retry", in: .screen(home))
        tap(card, about: item(1), in: .screen(home))

        #expect(repository.events == [
            .viewed("saved", in: .screen(home)),
            .viewed(card, about: item(1), in: .screen(home)),
            .tapped("retry", in: .screen(home)),
            .tapped(card, about: item(1), in: .screen(home))
        ])
    }

    @Test("A card scrolled away from and back to is seen twice, because it was")
    func everySighting() {
        view(card, about: item(1), in: .list(home, beauty, index: 0))
        view(card, about: item(1), in: .list(home, beauty, index: 0))

        #expect(sightings == 2)
    }

    @Test("Every tap counts, even on the same card")
    func everyTap() {
        tap(card, about: item(1), in: .list(home, beauty, index: 0))
        tap(card, about: item(1), in: .list(home, beauty, index: 0))

        #expect(repository.events.count == 2)
    }

    @Test("A position before the start of a list is not reported, seen or tapped")
    func negativePosition() {
        view(card, about: item(1), in: .list(home, beauty, index: -1))
        tap(card, in: .list(home, beauty, index: -1))

        #expect(repository.events.isEmpty)
    }

    @Test("Asking for consent and sending what is held both go to the repository")
    func consentAndFlush() async {
        await DefaultRequestTrackingConsentUseCase(repository: repository)()
        DefaultSendHeldTrackingUseCase(repository: repository)()

        #expect(repository.timesAskedForConsent == 1)
        #expect(repository.flushCount == 1)
    }
}

@Suite("The words events are made of")
struct ModelTests {
    @Test("Every place an event can happen knows its screen")
    func contextScreen() {
        let bag = "bag"

        #expect(TrackingContext.screen(bag).screen == bag)
        #expect(TrackingContext.list(bag, TrackingContext.List(id: "bag", name: "Bag"), index: 3).screen == bag)
    }
}
