import Session
import SessionTestSupport
import SnapshotTesting
import SwiftUI
import Testing
@testable import AccountUI
@testable import AccountUITestSupport

@MainActor
@Test("A signed-out shopper is offered a way in, not an empty account")
func aSignedOutShopperIsOfferedAWayIn() {
    let screen = AccountScreenView(
        viewModel: AccountScreenViewModel(
            getSession: StubGetSession(.guest),
            observeSession: StubObserveSession(.guest),
            logoutUseCase: SpyLogout()
        ),
        loginButton: AnyView(Button("Sign In") {}),
        navigation: SpyAccountNavigation()
    )

    assertSnapshot(of: screen, as: .image(layout: .device(config: .iPhone13)))
}
