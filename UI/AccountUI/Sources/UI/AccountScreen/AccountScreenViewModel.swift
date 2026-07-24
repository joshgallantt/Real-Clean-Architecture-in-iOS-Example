import Combine
import Foundation
import Session

@MainActor
public final class AccountScreenViewModel: ObservableObject {
    @Published private(set) var session: Session = .guest

    private let getSession: GetSessionUseCase
    private let observeSession: ObserveSessionUseCase
    private let logoutUseCase: LogoutUseCase
    private let navigation: AccountNavigation
    private var cancellables = Set<AnyCancellable>()

    var currentUser: User? { session.user }

    public init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        logoutUseCase: LogoutUseCase,
        navigation: AccountNavigation
    ) {
        self.getSession = getSession
        self.observeSession = observeSession
        self.logoutUseCase = logoutUseCase
        self.navigation = navigation
    }

    func onAppear() {
        session = getSession.execute()

        guard cancellables.isEmpty else { return }
        observeSession.execute()
            .sink { [weak self] session in
                guard let self else { return }
                self.session = session
                if session.isLoggedIn {
                    self.navigation.dismissLogin()
                }
            }
            .store(in: &cancellables)
    }

    func didTapLogIn() {
        navigation.openLogin()
    }

    func didTapLogOut() async {
        await logoutUseCase.execute()
    }
}
