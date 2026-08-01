import Foundation
import Testing
import Session
@testable import AccountUI

@MainActor
@Suite("Account screen")
struct AccountScreenViewModelTests {
    private func makeViewModel(
        getSession: StubGetSession = StubGetSession(),
        observeSession: SpyObserveSession = SpyObserveSession(),
        logoutUseCase: SpyLogout = SpyLogout()
    ) -> AccountScreenViewModel {
        AccountScreenViewModel(
            getSession: getSession,
            observeSession: observeSession,
            logoutUseCase: logoutUseCase
        )
    }

    @Test("Appearing reads who is currently signed in")
    func loadsTheCurrentSession() {
        let getSession = StubGetSession()
        getSession.session = .authenticated(.fixture())
        let viewModel = makeViewModel(
            getSession: getSession,
            observeSession: SpyObserveSession(initial: .authenticated(.fixture()))
        )

        viewModel.onAppear()

        #expect(viewModel.currentUser == .fixture())
    }

    @Test("A guest has nobody to show")
    func guestHasNoCurrentUser() {
        let viewModel = makeViewModel()

        viewModel.onAppear()

        #expect(viewModel.currentUser == nil)
    }

    @Test("Appearing subscribes to session changes only once, however often it happens")
    func subscribesOnce() {
        let observeSession = SpyObserveSession()
        let viewModel = makeViewModel(observeSession: observeSession)

        viewModel.onAppear()
        viewModel.onAppear()
        viewModel.onAppear()

        #expect(observeSession.callCount == 1)
    }

    @Test("Signing in after arriving updates who is shown")
    func followsSessionChanges() {
        let observeSession = SpyObserveSession()
        let viewModel = makeViewModel(observeSession: observeSession)
        viewModel.onAppear()

        observeSession.send(.authenticated(.fixture()))

        #expect(viewModel.currentUser == .fixture())
    }

    @Test("Logging out calls the use case")
    func logsOut() async {
        let logoutUseCase = SpyLogout()
        let viewModel = makeViewModel(logoutUseCase: logoutUseCase)

        await viewModel.didTapLogOut()

        #expect(logoutUseCase.callCount == 1)
    }
}
