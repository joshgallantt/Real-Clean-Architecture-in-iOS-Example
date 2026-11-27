import Session
import SessionTestSupport
import SnapshotTesting
import SwiftUI
import Testing
import Tracking
import TrackingTestSupport
@testable import AccountUI
@testable import AccountUITestSupport

@MainActor
@Test("A signed-out shopper is offered a way in, not an empty account")
func aSignedOutShopperIsOfferedAWayIn() {
    let screen = AccountScreenView(
        viewModel: AccountScreenViewModel(
            getSession: StubGetSessionUseCase(.guest),
            observeSession: SpyObserveSessionUseCase(.guest),
            logoutUseCase: SpyLogoutUseCase(),
            navigation: SpyAccountNavigation(),
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase()
        ),
        loginButton: AnyView(Button("Sign In") {})
    )

    assertSnapshot(of: screen, as: .image(layout: .device(config: .iPhone13)))
}
