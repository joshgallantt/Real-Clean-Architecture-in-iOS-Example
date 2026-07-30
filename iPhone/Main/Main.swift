import SwiftUI
import AuthUIDI
import OnboardingUIDI
import SheetUIDI
import SnackbarUIDI

@main
struct Main: App {
    @StateObject private var viewModel = Injector.shared.makeMainViewModel()

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch viewModel.phase {
                case .splash:
                    SplashView()
                case .welcome:
                    Injector.shared.authUIDI.welcomeView(
                        onContinueAsGuest: { viewModel.continueAsGuest() },
                        onAuthenticated: { viewModel.authenticationFinished() }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 160)
                    .ignoresSafeArea(edges: .top)
                case .onboarding:
                    Injector.shared.onboardingUIDI.onboardingView(
                        onFinish: { viewModel.continueAsGuest() }
                    )
                case .main:
                    TabScreen(
                        navigator: Injector.shared.navigator,
                        snackbarPresenter: Injector.shared.snackbarUIDI.presenter,
                        homeView: Injector.shared.homeView,
                        searchView: Injector.shared.searchView,
                        wishlistView: Injector.shared.wishlistView,
                        bagView: Injector.shared.bagView,
                        accountView: Injector.shared.accountView
                    )
                }
            }
            .sheetHost(Injector.shared.sheetUIDI.presenter)
            .task {
                await viewModel.onAppear()
            }
        }
    }
}
