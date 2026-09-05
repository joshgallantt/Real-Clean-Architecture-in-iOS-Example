import Foundation
import ProductTestSupport
import SessionTestSupport
import Testing
import Session
@testable import AccountUI
@testable import AccountUITestSupport

@MainActor
@Suite("Account screen")
struct AccountScreenViewModelTests {
    private func makeViewModel(
        getSession: StubGetSessionUseCase = StubGetSessionUseCase(),
        observeSession: SpyObserveSessionUseCase = SpyObserveSessionUseCase(),
        logoutUseCase: SpyLogoutUseCase = SpyLogoutUseCase()
    ) -> AccountScreenViewModel {
        AccountScreenViewModel(
            getSession: getSession,
            observeSession: observeSession,
            logoutUseCase: logoutUseCase
        )
    }

    @Test("Appearing reads who is currently signed in")
    func loadsTheCurrentSession() {
        let getSession = StubGetSessionUseCase()
        getSession.session = .authenticated(.fixture())
        let viewModel = makeViewModel(
            getSession: getSession,
            observeSession: SpyObserveSessionUseCase(initial: .authenticated(.fixture()))
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
        let observeSession = SpyObserveSessionUseCase()
        let viewModel = makeViewModel(observeSession: observeSession)

        viewModel.onAppear()
        viewModel.onAppear()
        viewModel.onAppear()

        #expect(observeSession.callCount == 1)
    }

    @Test("Signing in after arriving updates who is shown")
    func followsSessionChanges() {
        let observeSession = SpyObserveSessionUseCase()
        let viewModel = makeViewModel(observeSession: observeSession)
        viewModel.onAppear()

        observeSession.send(.authenticated(.fixture()))

        #expect(viewModel.currentUser == .fixture())
    }

    @Test("Logging out calls the use case")
    func logsOut() async {
        let logoutUseCase = SpyLogoutUseCase()
        let viewModel = makeViewModel(logoutUseCase: logoutUseCase)

        await viewModel.didTapLogOut()

        #expect(logoutUseCase.callCount == 1)
    }
}
