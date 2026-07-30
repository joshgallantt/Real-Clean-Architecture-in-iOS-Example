import SwiftUI
import AuthUIDI
import OnboardingUIDI
import SheetUIDI
import SnackbarUIDI

@main
struct Main: App {
    @StateObject private var viewModel = CompositionRoot.shared.makeMainViewModel()

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
        }
    }
}
