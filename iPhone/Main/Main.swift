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
                    CompositionRoot.shared.authUIDI.welcomeView(
                        onContinueAsGuest: { viewModel.continueAsGuest() },
                        onAuthenticated: { viewModel.authenticationFinished() }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 160)
                    .ignoresSafeArea(edges: .top)
                case .onboarding:
                    CompositionRoot.shared.onboardingUIDI.onboardingView(
                        onFinish: { viewModel.continueAsGuest() }
                    )
                case .main:
                    TabScreen(
                        navigator: CompositionRoot.shared.navigator,
                        snackbarPresenter: CompositionRoot.shared.snackbarUIDI.presenter,
                        homeView: CompositionRoot.shared.homeView,
                        searchView: CompositionRoot.shared.searchView,
                        wishlistView: CompositionRoot.shared.wishlistView,
                        bagView: CompositionRoot.shared.bagView,
                        accountView: CompositionRoot.shared.accountView
                    )
                }
            }
            .sheetHost(CompositionRoot.shared.sheetUIDI.presenter)
            .task {
                await viewModel.onAppear()
            }
        }
    }
}
