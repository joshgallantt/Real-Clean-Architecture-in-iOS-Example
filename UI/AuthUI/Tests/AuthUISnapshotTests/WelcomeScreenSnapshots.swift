import Session
import SessionTestSupport
import SheetUITestSupport
import SnapshotTesting
import SwiftUI
import Testing
import Tracking
import TrackingTestSupport
@testable import AuthUIDI

@MainActor
@Test("The welcome screen offers signing in and carrying on as a guest")
func theWelcomeScreenOffersBothWaysIn() {
    let screen = WelcomeScreenView(
        viewModel: WelcomeScreenViewModel(
            presenter: AuthPresenter(
                sheetPresenting: SpySheetPresenting(),
                loginUseCase: SpyLoginUseCase(),
                createAccountUseCase: SpyCreateAccountUseCase(),
                getSession: StubGetSessionUseCase(.guest),
                trackScreenView: SpyTrackScreenViewUseCase(),
                trackElementView: SpyTrackElementViewUseCase(),
                trackElementInteraction: SpyTrackElementInteractionUseCase(),
                trackEvent: SpyTrackEventUseCase()
            ),
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase(),
            onContinueAsGuest: {},
            onAuthenticated: {}
        )
    )

    assertSnapshot(of: screen, as: .image(layout: .device(config: .iPhone13)))
}
