import SwiftUI
import AuthUIDI
import OnboardingUIDI
import SheetUIDI
import SnackbarUIDI

@main
struct Main: App {
    @State private var viewModel = CompositionRoot.shared.makeMainViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch viewModel.phase {
                case .splash:
                    SplashView()
                case .welcome:
                    CompositionRoot.shared.presentation.auth.welcomeView(
                        onContinueAsGuest: { viewModel.continueAsGuest() },
                        onAuthenticated: { viewModel.authenticationFinished() }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 160)
                    .ignoresSafeArea(edges: .top)
                case .onboarding:
                    CompositionRoot.shared.presentation.onboarding.onboardingView(
                        onFinish: { viewModel.continueAsGuest() }
                    )
                case .main:
                    TabScreen(
                        navigator: CompositionRoot.shared.presentation.navigator,
                        snackbarPresenter: CompositionRoot.shared.presentation.snackbar.presenter,
                        homeView: CompositionRoot.shared.presentation.homeView,
                        searchView: CompositionRoot.shared.presentation.searchView,
                        wishlistView: CompositionRoot.shared.presentation.wishlistView,
                        bagView: CompositionRoot.shared.presentation.bagView,
                        accountView: CompositionRoot.shared.presentation.accountView
                    )
                }
            }
            .sheetHost(CompositionRoot.shared.presentation.sheet.presenter)
            .task {
                await viewModel.onAppear()
            }
            /// List views are held back and sent in batches, and a suspended app never gets to the
            /// end of its batch window. Going to the background is the last moment to send them.
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { CompositionRoot.shared.sendHeldBackTracking() }
            }
        }
    }
}
