import Foundation
import Testing
import Session
@testable import WishlistUI

@MainActor
@Suite("The wishlist tab")
struct WishlistScreenViewModelTests {
    @Test("A guest is not shown as signed in")
    func guestIsNotAuthenticated() {
        let viewModel = WishlistScreenViewModel(observeSession: StubObserveSession())

        viewModel.onAppear()

        #expect(viewModel.isAuthenticated == false)
    }

    @Test("Someone already signed in when the tab appears is shown as signed in")
    func alreadySignedInIsAuthenticated() {
        let viewModel = WishlistScreenViewModel(observeSession: StubObserveSession(initial: .authenticated(.fixture())))

        viewModel.onAppear()

        #expect(viewModel.isAuthenticated)
    }

    @Test("Signing in after arriving is picked up too")
    func signingInLaterIsPickedUp() {
        let observeSession = StubObserveSession()
        let viewModel = WishlistScreenViewModel(observeSession: observeSession)
        viewModel.onAppear()

        observeSession.send(.authenticated(.fixture()))

        #expect(viewModel.isAuthenticated)
    }

    @Test("Signing out after arriving is picked up too")
    func signingOutLaterIsPickedUp() {
        let observeSession = StubObserveSession(initial: .authenticated(.fixture()))
        let viewModel = WishlistScreenViewModel(observeSession: observeSession)
        viewModel.onAppear()

        observeSession.send(.guest)

        #expect(viewModel.isAuthenticated == false)
    }

    @Test("Appearing subscribes to session changes only once, however often it happens")
    func subscribesOnce() {
        let observeSession = StubObserveSession()
        let viewModel = WishlistScreenViewModel(observeSession: observeSession)

        viewModel.onAppear()
        viewModel.onAppear()
        viewModel.onAppear()

        #expect(observeSession.callCount == 1)
    }
}
